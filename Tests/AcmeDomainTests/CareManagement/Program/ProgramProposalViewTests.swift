@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newProgramProposal("code-717", label: "label-626")
        let view = CareManagement.toProgramProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toProgramProposalViews([item, item]).count == 2)
    }
}
