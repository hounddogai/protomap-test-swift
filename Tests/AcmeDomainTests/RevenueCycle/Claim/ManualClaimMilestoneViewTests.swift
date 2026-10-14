@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualClaimMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newManualClaimMilestone("code-9", name: "name-291")
        let view = RevenueCycle.toManualClaimMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toManualClaimMilestoneViews([item, item]).count == 2)
    }
}
