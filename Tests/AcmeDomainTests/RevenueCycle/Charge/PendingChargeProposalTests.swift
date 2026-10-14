@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingChargeProposalTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newPendingChargeProposal("code-758", title: "title-379")
        #expect(item.status == RevenueCycle.PendingChargeProposalStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = RevenueCycle.newPendingChargeProposal("code-758", title: "title-379")
        try item.moveTo(RevenueCycle.PendingChargeProposalStatus.inProgress)
        #expect(item.status == RevenueCycle.PendingChargeProposalStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newPendingChargeProposal("code-758", title: "title-379")
        item.status = RevenueCycle.PendingChargeProposalStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.PendingChargeProposalStatus.planned) }
    }
}
