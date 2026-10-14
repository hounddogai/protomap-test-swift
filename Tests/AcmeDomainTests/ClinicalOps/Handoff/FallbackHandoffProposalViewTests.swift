@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackHandoffProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newFallbackHandoffProposal("code-773", name: "name-302")
        let view = ClinicalOps.toFallbackHandoffProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toFallbackHandoffProposalViews([item, item]).count == 2)
    }
}
