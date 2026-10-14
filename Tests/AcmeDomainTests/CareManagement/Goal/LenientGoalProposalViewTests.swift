@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientGoalProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newLenientGoalProposal("code-715", label: "label-520")
        let view = CareManagement.toLenientGoalProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toLenientGoalProposalViews([item, item]).count == 2)
    }
}
