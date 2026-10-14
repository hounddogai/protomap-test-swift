@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredAuthorizationBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newTieredAuthorizationBundle("code-599", title: "title-734")
        let view = RevenueCycle.toTieredAuthorizationBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toTieredAuthorizationBundleViews([item, item]).count == 2)
    }
}
