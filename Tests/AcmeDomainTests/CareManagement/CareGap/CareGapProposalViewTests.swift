@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCareGapProposal("code-812", label: "label-726")
        let view = CareManagement.toCareGapProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCareGapProposalViews([item, item]).count == 2)
    }
}
