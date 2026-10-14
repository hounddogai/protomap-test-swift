@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingStatementProposalTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newPendingStatementProposal("code-452", name: "name-63")
        #expect(item.status == RevenueCycle.PendingStatementProposalStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = RevenueCycle.newPendingStatementProposal("code-452", name: "name-63")
        try item.moveTo(RevenueCycle.PendingStatementProposalStatus.ready)
        #expect(item.status == RevenueCycle.PendingStatementProposalStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newPendingStatementProposal("code-452", name: "name-63")
        item.status = RevenueCycle.PendingStatementProposalStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.PendingStatementProposalStatus.idle) }
    }
}
