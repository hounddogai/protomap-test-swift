@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredConsentFormProposalTests {
    @Test func startsInRequested() throws {
        let item = Consent.newTieredConsentFormProposal("code-149", label: "label-272")
        #expect(item.status == Consent.TieredConsentFormProposalStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newTieredConsentFormProposal("code-149", label: "label-272")
        try item.moveTo(Consent.TieredConsentFormProposalStatus.granted)
        #expect(item.status == Consent.TieredConsentFormProposalStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newTieredConsentFormProposal("code-149", label: "label-272")
        item.status = Consent.TieredConsentFormProposalStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.TieredConsentFormProposalStatus.requested) }
    }
}
