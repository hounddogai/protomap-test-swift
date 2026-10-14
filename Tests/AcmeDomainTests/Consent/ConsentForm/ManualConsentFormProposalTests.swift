@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualConsentFormProposalTests {
    @Test func startsInCreated() throws {
        let item = Consent.newManualConsentFormProposal("code-30", name: "name-732")
        #expect(item.status == Consent.ManualConsentFormProposalStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Consent.newManualConsentFormProposal("code-30", name: "name-732")
        try item.moveTo(Consent.ManualConsentFormProposalStatus.published)
        #expect(item.status == Consent.ManualConsentFormProposalStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newManualConsentFormProposal("code-30", name: "name-732")
        item.status = Consent.ManualConsentFormProposalStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ManualConsentFormProposalStatus.created) }
    }
}
