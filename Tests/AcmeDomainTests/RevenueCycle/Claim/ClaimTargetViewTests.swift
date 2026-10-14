@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newClaimTarget("code-408", name: "name-488")
        let view = RevenueCycle.toClaimTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toClaimTargetViews([item, item]).count == 2)
    }
}
