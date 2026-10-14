@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCleaningProposal("code-590", label: "label-14")
        let view = BedManagement.toCleaningProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCleaningProposalViews([item, item]).count == 2)
    }
}
