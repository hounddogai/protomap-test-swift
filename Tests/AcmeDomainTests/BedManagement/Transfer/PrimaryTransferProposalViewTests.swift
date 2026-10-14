@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryTransferProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newPrimaryTransferProposal("code-938", name: "name-396")
        let view = BedManagement.toPrimaryTransferProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toPrimaryTransferProposalViews([item, item]).count == 2)
    }
}
