@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRegionalIsolationProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newRegionalIsolationProposal("code-628", title: "title-511")
        let view = BedManagement.toRegionalIsolationProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toRegionalIsolationProposalViews([item, item]).count == 2)
    }
}
