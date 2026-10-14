@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newClaimRollup("code-333", name: "name-337")
        let view = RevenueCycle.toClaimRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toClaimRollupViews([item, item]).count == 2)
    }
}
