@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newClaimProposal("code-735", name: "name-861")
        let view = RevenueCycle.toClaimProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toClaimProposalViews([item, item]).count == 2)
    }
}
