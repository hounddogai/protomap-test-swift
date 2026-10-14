@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingTaskProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newPendingTaskProposal("code-776", label: "label-775")
        let view = ClinicalOps.toPendingTaskProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toPendingTaskProposalViews([item, item]).count == 2)
    }
}
