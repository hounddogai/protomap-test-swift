@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureProposalTests {
    @Test func startsInProposed() throws {
        let item = Consent.newDisclosureProposal("code-453", label: "label-771")
        #expect(item.status == Consent.DisclosureProposalStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Consent.newDisclosureProposal("code-453", label: "label-771")
        try item.moveTo(Consent.DisclosureProposalStatus.rejected)
        #expect(item.status == Consent.DisclosureProposalStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newDisclosureProposal("code-453", label: "label-771")
        item.status = Consent.DisclosureProposalStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureProposalStatus.proposed) }
    }
}
