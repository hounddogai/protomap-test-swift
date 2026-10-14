@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedWitnessProposalTests {
    @Test func startsInNew() throws {
        let item = Consent.newCappedWitnessProposal("code-169", name: "name-586")
        #expect(item.status == Consent.CappedWitnessProposalStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Consent.newCappedWitnessProposal("code-169", name: "name-586")
        try item.moveTo(Consent.CappedWitnessProposalStatus.running)
        #expect(item.status == Consent.CappedWitnessProposalStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newCappedWitnessProposal("code-169", name: "name-586")
        item.status = Consent.CappedWitnessProposalStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.CappedWitnessProposalStatus.new) }
    }
}
