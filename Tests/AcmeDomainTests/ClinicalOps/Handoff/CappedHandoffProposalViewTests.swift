@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedHandoffProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newCappedHandoffProposal("code-219", title: "title-842")
        let view = ClinicalOps.toCappedHandoffProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toCappedHandoffProposalViews([item, item]).count == 2)
    }
}
