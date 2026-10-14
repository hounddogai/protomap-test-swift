@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryCensusProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newPrimaryCensusProposal("code-651", title: "title-904")
        let view = BedManagement.toPrimaryCensusProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toPrimaryCensusProposalViews([item, item]).count == 2)
    }
}
