@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultTransferProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newDefaultTransferProposal("code-402", label: "label-118")
        let view = BedManagement.toDefaultTransferProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toDefaultTransferProposalViews([item, item]).count == 2)
    }
}
