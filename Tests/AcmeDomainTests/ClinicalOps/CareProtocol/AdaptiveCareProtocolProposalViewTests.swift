@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveCareProtocolProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAdaptiveCareProtocolProposal("code-781", label: "label-857")
        let view = ClinicalOps.toAdaptiveCareProtocolProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAdaptiveCareProtocolProposalViews([item, item]).count == 2)
    }
}
