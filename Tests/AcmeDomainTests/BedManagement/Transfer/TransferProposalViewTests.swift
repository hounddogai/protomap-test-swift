@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newTransferProposal("code-402", label: "label-94")
        let view = BedManagement.toTransferProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toTransferProposalViews([item, item]).count == 2)
    }
}
