@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLenientTaskProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newLenientTaskProposal("code-873", label: "label-173")
        let view = ClinicalOps.toLenientTaskProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toLenientTaskProposalViews([item, item]).count == 2)
    }
}
