@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCredentialProposal("code-663", title: "title-751")
        let view = Staffing.toCredentialProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCredentialProposalViews([item, item]).count == 2)
    }
}
