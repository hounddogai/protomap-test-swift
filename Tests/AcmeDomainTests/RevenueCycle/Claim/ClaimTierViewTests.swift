@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newClaimTier("code-408", name: "name-34")
        let view = RevenueCycle.toClaimTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toClaimTierViews([item, item]).count == 2)
    }
}
