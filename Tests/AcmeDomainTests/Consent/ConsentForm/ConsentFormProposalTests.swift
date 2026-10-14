@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormProposalTests {
    @Test func startsInProposed() throws {
        let item = Consent.newConsentFormProposal("code-413", label: "label-661")
        #expect(item.status == Consent.ConsentFormProposalStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Consent.newConsentFormProposal("code-413", label: "label-661")
        try item.moveTo(Consent.ConsentFormProposalStatus.approved)
        #expect(item.status == Consent.ConsentFormProposalStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newConsentFormProposal("code-413", label: "label-661")
        item.status = Consent.ConsentFormProposalStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormProposalStatus.proposed) }
    }
}
