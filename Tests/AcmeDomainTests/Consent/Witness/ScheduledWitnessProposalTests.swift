@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledWitnessProposalTests {
    @Test func startsInOpen() throws {
        let item = Consent.newScheduledWitnessProposal("code-969", name: "name-440")
        #expect(item.status == Consent.ScheduledWitnessProposalStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Consent.newScheduledWitnessProposal("code-969", name: "name-440")
        try item.moveTo(Consent.ScheduledWitnessProposalStatus.resolved)
        #expect(item.status == Consent.ScheduledWitnessProposalStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newScheduledWitnessProposal("code-969", name: "name-440")
        item.status = Consent.ScheduledWitnessProposalStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ScheduledWitnessProposalStatus.`open`) }
    }
}
