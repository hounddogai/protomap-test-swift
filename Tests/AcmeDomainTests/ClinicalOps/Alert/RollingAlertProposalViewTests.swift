@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingAlertProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newRollingAlertProposal("code-312", title: "title-522")
        let view = ClinicalOps.toRollingAlertProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toRollingAlertProposalViews([item, item]).count == 2)
    }
}
