@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictRoundingProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newStrictRoundingProposal("code-716", title: "title-536")
        let view = ClinicalOps.toStrictRoundingProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toStrictRoundingProposalViews([item, item]).count == 2)
    }
}
