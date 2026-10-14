@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingCareProtocolMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newPendingCareProtocolMilestone("code-276", name: "name-439")
        let view = ClinicalOps.toPendingCareProtocolMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toPendingCareProtocolMilestoneViews([item, item]).count == 2)
    }
}
