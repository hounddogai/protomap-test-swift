@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingStatementProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newPendingStatementProposal("code-452", name: "name-63")
        let view = RevenueCycle.toPendingStatementProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toPendingStatementProposalViews([item, item]).count == 2)
    }
}
