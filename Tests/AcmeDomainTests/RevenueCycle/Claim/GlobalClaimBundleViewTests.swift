@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalClaimBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newGlobalClaimBundle("code-559", name: "name-975")
        let view = RevenueCycle.toGlobalClaimBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toGlobalClaimBundleViews([item, item]).count == 2)
    }
}
