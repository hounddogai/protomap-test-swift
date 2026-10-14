@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledBedBoardProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newScheduledBedBoardProposal("code-99", label: "label-989")
        let view = BedManagement.toScheduledBedBoardProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toScheduledBedBoardProposalViews([item, item]).count == 2)
    }
}
