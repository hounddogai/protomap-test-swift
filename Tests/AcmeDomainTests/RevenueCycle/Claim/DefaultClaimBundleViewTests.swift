@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultClaimBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newDefaultClaimBundle("code-852", title: "title-115")
        let view = RevenueCycle.toDefaultClaimBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toDefaultClaimBundleViews([item, item]).count == 2)
    }
}
