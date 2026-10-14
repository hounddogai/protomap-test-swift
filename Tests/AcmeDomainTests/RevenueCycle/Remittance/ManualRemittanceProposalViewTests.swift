@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualRemittanceProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newManualRemittanceProposal("code-751", title: "title-364")
        let view = RevenueCycle.toManualRemittanceProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toManualRemittanceProposalViews([item, item]).count == 2)
    }
}
