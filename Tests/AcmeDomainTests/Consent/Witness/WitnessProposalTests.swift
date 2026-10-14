@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessProposalTests {
    @Test func startsInIdle() throws {
        let item = Consent.newWitnessProposal("code-459", title: "title-825")
        #expect(item.status == Consent.WitnessProposalStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Consent.newWitnessProposal("code-459", title: "title-825")
        try item.moveTo(Consent.WitnessProposalStatus.draining)
        #expect(item.status == Consent.WitnessProposalStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newWitnessProposal("code-459", title: "title-825")
        item.status = Consent.WitnessProposalStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessProposalStatus.idle) }
    }
}
