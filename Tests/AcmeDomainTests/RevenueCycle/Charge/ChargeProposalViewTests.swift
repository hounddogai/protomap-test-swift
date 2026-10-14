@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newChargeProposal("code-170", name: "name-891")
        let view = RevenueCycle.toChargeProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toChargeProposalViews([item, item]).count == 2)
    }
}
