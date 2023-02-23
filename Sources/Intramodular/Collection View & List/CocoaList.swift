//
// Copyright (c) Vatsal Manot
//

import Swift
import SwiftUI

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)

public struct CocoaList<
    SectionType: Identifiable,
    ItemType: Identifiable,
    Data: RandomAccessCollection,
    SectionHeader: View,
    SectionFooter: View,
    RowContent: View
>: UIViewControllerRepresentable where Data.Element == ListSection<SectionType, ItemType> {
    public typealias Offset = ScrollView<AnyView>.ContentOffset
    public typealias UIViewControllerType = UIHostingTableViewController<SectionType, ItemType, Data, SectionHeader, SectionFooter, RowContent>
    
    @usableFromInline
    let data: Data
    @usableFromInline
    let sectionHeader: (SectionType) -> SectionHeader
    @usableFromInline
    let sectionFooter: (SectionType) -> SectionFooter
    @usableFromInline
    let rowContent: (ItemType, IndexPath) -> RowContent
    
    @usableFromInline
    var style: UITableView.Style = .plain
    
    #if !os(tvOS)
    @usableFromInline
    var separatorStyle: UITableViewCell.SeparatorStyle = .singleLine
    #endif
    
    @usableFromInline
    var scrollViewConfiguration: CocoaScrollViewConfiguration<AnyView> = nil
    
    public init(
        _ data: Data,
        sectionHeader: @escaping (SectionType) -> SectionHeader,
        sectionFooter: @escaping (SectionType) -> SectionFooter,
        rowContent: @escaping (ItemType, IndexPath) -> RowContent
    ) {
        self.data = data
        self.sectionHeader = sectionHeader
        self.sectionFooter = sectionFooter
        self.rowContent = rowContent
    }
    
    public func makeUIViewController(context: Context) -> UIViewControllerType {
        .init(
            data,
            style: style,
            sectionHeader: sectionHeader,
            sectionFooter: sectionFooter,
            rowContent: rowContent
        )
    }
    
    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        uiViewController.data = data
        uiViewController.sectionHeader = sectionHeader
        uiViewController.sectionFooter = sectionFooter
        uiViewController.rowContent = rowContent
        
        uiViewController.initialContentAlignment = context.environment.initialContentAlignment
        
        var scrollViewConfiguration = self.scrollViewConfiguration
        
        scrollViewConfiguration.update(from: context.environment)
        
        uiViewController.scrollViewConfiguration = scrollViewConfiguration
        
        #if !os(tvOS)
        uiViewController.tableView.separatorStyle = separatorStyle
        #endif
        
        uiViewController.reloadData()
    }
}

extension CocoaList {
    public init<_Item: Hashable>(
        _ data: Data,
        sectionHeader: @escaping (SectionType) -> SectionHeader,
        sectionFooter: @escaping (SectionType) -> SectionFooter,
        rowContent: @escaping (_Item, IndexPath) -> RowContent
    ) where ItemType == _HashIdentifiableValue<_Item> {
        self.data = data
        self.sectionHeader = sectionHeader
        self.sectionFooter = sectionFooter
        self.rowContent = { rowContent($0.value, $1) }
    }
    
    public init<_SectionType: Hashable, _Item: Hashable>(
        _ data: Data,
        sectionHeader: @escaping (_SectionType) -> SectionHeader,
        sectionFooter: @escaping (_SectionType) -> SectionFooter,
        rowContent: @escaping (_Item, IndexPath) -> RowContent
    ) where SectionType == _HashIdentifiableValue<_SectionType>, ItemType == _HashIdentifiableValue<_Item> {
        self.data = data
        self.sectionHeader = { sectionHeader($0.value) }
        self.sectionFooter = { sectionFooter($0.value) }
        self.rowContent = { rowContent($0.value, $1) }
    }
    
    public init<_SectionType: Hashable, _Item: Hashable>(
        _ data: [ListSection<_SectionType, _Item>],
        sectionHeader: @escaping (_SectionType) -> SectionHeader,
        sectionFooter: @escaping (_SectionType) -> SectionFooter,
        rowContent: @escaping (_Item, IndexPath) -> RowContent
    ) where Data == Array<ListSection<SectionType, ItemType>>, SectionType == _HashIdentifiableValue<_SectionType>, ItemType == _HashIdentifiableValue<_Item> {
        self.data = data.map({ .init(model: .init($0.model), items: $0.items.map(_HashIdentifiableValue.init)) })
        self.sectionHeader = { sectionHeader($0.value) }
        self.sectionFooter = { sectionFooter($0.value) }
        self.rowContent = { rowContent($0.value, $1) }
    }
}

extension CocoaList where
    SectionType == _KeyPathHashIdentifiableValue<Int, Int>,
    SectionHeader == Never,
    SectionFooter == Never
{
    public init<
        _ItemType,
        _ItemID,
        Items: RandomAccessCollection
    >(
        _ items: Items,
        id: KeyPath<_ItemType, _ItemID>,
        @ViewBuilder rowContent: @escaping (_ItemType, IndexPath) -> RowContent
    ) where Data == AnyRandomAccessCollection<ListSection<SectionType, ItemType>>, Items.Element == _ItemType, ItemType == _KeyPathHashIdentifiableValue<_ItemType, _ItemID> {
        self.init(
            AnyRandomAccessCollection([ListSection(_KeyPathHashIdentifiableValue(value: 0, keyPath: \.self), items: items.elements(identifiedBy: id))]),
            sectionHeader: Never.produce,
            sectionFooter: Never.produce,
            rowContent: { rowContent($0.value, $1) }
        )
    }
}

extension CocoaList where
    Data: RangeReplaceableCollection,
    SectionType == _KeyPathHashIdentifiableValue<Int, Int>,
    SectionHeader == Never,
    SectionFooter == Never
{
    public init<Items: RandomAccessCollection>(
        _ items: Items,
        @ViewBuilder rowContent: @escaping (ItemType, IndexPath) -> RowContent
    ) where Items.Element == ItemType {
        var data = Data.init()
        
        data.append(.init(_KeyPathHashIdentifiableValue(value: 0, keyPath: \.self), items: items))
        
        self.init(
            data,
            sectionHeader: Never.produce,
            sectionFooter: Never.produce,
            rowContent: rowContent
        )
    }
    
}

extension CocoaList where
    Data == Array<ListSection<SectionType, ItemType>>,
    SectionType == _KeyPathHashIdentifiableValue<Int, Int>,
    SectionHeader == Never,
    SectionFooter == Never
{
    public init<Items: RandomAccessCollection>(
        _ items: Items,
        @ViewBuilder rowContent: @escaping (ItemType, IndexPath) -> RowContent
    ) where Items.Element == ItemType {
        self.init(
            [.init(_KeyPathHashIdentifiableValue(value: 0, keyPath: \.self), items: items)],
            sectionHeader: Never.produce,
            sectionFooter: Never.produce,
            rowContent: rowContent
        )
    }
}

// MARK: - API

extension CocoaList {
    public func listStyle(_ style: UITableView.Style) -> Self {
        then({ $0.style = style })
    }
    
    #if !os(tvOS)
    public func listSeparatorStyle(_ separatorStyle: UITableViewCell.SeparatorStyle) -> Self {
        then({ $0.separatorStyle = separatorStyle })
    }
    #endif
}

extension CocoaList {
    public func alwaysBounceVertical(_ alwaysBounceVertical: Bool) -> Self {
        then({ $0.scrollViewConfiguration.alwaysBounceVertical = alwaysBounceVertical })
    }
    
    public func alwaysBounceHorizontal(_ alwaysBounceHorizontal: Bool) -> Self {
        then({ $0.scrollViewConfiguration.alwaysBounceHorizontal = alwaysBounceHorizontal })
    }
    
    public func onOffsetChange(_ body: @escaping (Offset) -> ()) -> Self {
        then({ $0.scrollViewConfiguration.onOffsetChange = body })
    }
    
    public func contentInsets(_ contentInset: EdgeInsets) -> Self {
        then({ $0.scrollViewConfiguration.contentInset = contentInset })
    }
    
    @_disfavoredOverload
    public func contentInsets(_ insets: UIEdgeInsets) -> Self {
        contentInsets(EdgeInsets(insets))
    }
    
    public func contentInsets(
        _ edges: Edge.Set = .all,
        _ length: CGFloat = 0
    ) -> Self {
        contentInsets(EdgeInsets(edges, length))
    }
    
    public func contentOffset(_ contentOffset: Binding<CGPoint>) -> Self {
        then({ $0.scrollViewConfiguration.contentOffset = contentOffset })
    }
}

@available(tvOS, unavailable)
extension CocoaList {
    public func onRefresh(_ body: @escaping () -> Void) -> Self {
        then({ $0.scrollViewConfiguration.onRefresh = body })
    }
    
    public func isRefreshing(_ isRefreshing: Bool) -> Self {
        then({ $0.scrollViewConfiguration.isRefreshing = isRefreshing })
    }
    
    public func refreshControlTintColor(_ color: UIColor?) -> Self {
        then({ $0.scrollViewConfiguration.refreshControlTintColor = color })
    }
}

#endif
