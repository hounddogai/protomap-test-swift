@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedDenialMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newBatchedDenialMilestone("code-388", name: "name-349")
        let view = RevenueCycle.toBatchedDenialMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toBatchedDenialMilestoneViews([item, item]).count == 2)
    }
}
