import SwiftUI
import UIKit

class RestrictedUIHostingController<Content: View>: UIHostingController<Content> {
    
    override var navigationController: UINavigationController? {
        return nil
    }
    
}
