@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultCareProtocolProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newDefaultCareProtocolProposal("code-916", title: "title-95")
        let view = ClinicalOps.toDefaultCareProtocolProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toDefaultCareProtocolProposalViews([item, item]).count == 2)
    }
}
