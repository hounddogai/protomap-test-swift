@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingChargeProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newPendingChargeProposal("code-758", title: "title-379")
        let view = RevenueCycle.toPendingChargeProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toPendingChargeProposalViews([item, item]).count == 2)
    }
}
