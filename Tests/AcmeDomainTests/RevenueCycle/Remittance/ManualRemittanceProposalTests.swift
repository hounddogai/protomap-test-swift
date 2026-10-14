@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualRemittanceProposalTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newManualRemittanceProposal("code-751", title: "title-364")
        #expect(item.status == RevenueCycle.ManualRemittanceProposalStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = RevenueCycle.newManualRemittanceProposal("code-751", title: "title-364")
        try item.moveTo(RevenueCycle.ManualRemittanceProposalStatus.queued)
        #expect(item.status == RevenueCycle.ManualRemittanceProposalStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newManualRemittanceProposal("code-751", title: "title-364")
        item.status = RevenueCycle.ManualRemittanceProposalStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ManualRemittanceProposalStatus.new) }
    }
}
