@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryGoalProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newPrimaryGoalProposal("code-93", label: "label-701")
        let view = CareManagement.toPrimaryGoalProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toPrimaryGoalProposalViews([item, item]).count == 2)
    }
}
