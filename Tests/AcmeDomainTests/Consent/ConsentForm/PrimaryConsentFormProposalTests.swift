@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryConsentFormProposalTests {
    @Test func startsInDraft() throws {
        let item = Consent.newPrimaryConsentFormProposal("code-152", name: "name-114")
        #expect(item.status == Consent.PrimaryConsentFormProposalStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Consent.newPrimaryConsentFormProposal("code-152", name: "name-114")
        try item.moveTo(Consent.PrimaryConsentFormProposalStatus.pending)
        #expect(item.status == Consent.PrimaryConsentFormProposalStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newPrimaryConsentFormProposal("code-152", name: "name-114")
        item.status = Consent.PrimaryConsentFormProposalStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.PrimaryConsentFormProposalStatus.draft) }
    }
}
