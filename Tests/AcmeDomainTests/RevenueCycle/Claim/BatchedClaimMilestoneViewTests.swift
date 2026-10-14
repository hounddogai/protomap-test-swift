@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedClaimMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newBatchedClaimMilestone("code-199", title: "title-207")
        let view = RevenueCycle.toBatchedClaimMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toBatchedClaimMilestoneViews([item, item]).count == 2)
    }
}
