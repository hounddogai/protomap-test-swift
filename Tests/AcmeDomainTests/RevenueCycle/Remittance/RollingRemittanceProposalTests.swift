@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingRemittanceProposalTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newRollingRemittanceProposal("code-362", title: "title-744")
        #expect(item.status == RevenueCycle.RollingRemittanceProposalStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = RevenueCycle.newRollingRemittanceProposal("code-362", title: "title-744")
        try item.moveTo(RevenueCycle.RollingRemittanceProposalStatus.completed)
        #expect(item.status == RevenueCycle.RollingRemittanceProposalStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newRollingRemittanceProposal("code-362", title: "title-744")
        item.status = RevenueCycle.RollingRemittanceProposalStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RollingRemittanceProposalStatus.planned) }
    }
}
