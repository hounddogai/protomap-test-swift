@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimProposalTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newClaimProposal("code-735", name: "name-861")
        #expect(item.status == RevenueCycle.ClaimProposalStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = RevenueCycle.newClaimProposal("code-735", name: "name-861")
        try item.moveTo(RevenueCycle.ClaimProposalStatus.completed)
        #expect(item.status == RevenueCycle.ClaimProposalStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newClaimProposal("code-735", name: "name-861")
        item.status = RevenueCycle.ClaimProposalStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimProposalStatus.planned) }
    }
}
