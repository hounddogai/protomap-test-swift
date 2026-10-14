@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryOutreachProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newPrimaryOutreachProposal("code-106", name: "name-296")
        let view = CareManagement.toPrimaryOutreachProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toPrimaryOutreachProposalViews([item, item]).count == 2)
    }
}
