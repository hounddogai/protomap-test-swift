@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledClaimMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newScheduledClaimMilestone("code-975", name: "name-262")
        let view = RevenueCycle.toScheduledClaimMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toScheduledClaimMilestoneViews([item, item]).count == 2)
    }
}
