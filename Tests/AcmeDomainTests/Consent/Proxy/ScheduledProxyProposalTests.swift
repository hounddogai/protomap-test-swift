@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledProxyProposalTests {
    @Test func startsInProposed() throws {
        let item = Consent.newScheduledProxyProposal("code-142", label: "label-114")
        #expect(item.status == Consent.ScheduledProxyProposalStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Consent.newScheduledProxyProposal("code-142", label: "label-114")
        try item.moveTo(Consent.ScheduledProxyProposalStatus.approved)
        #expect(item.status == Consent.ScheduledProxyProposalStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newScheduledProxyProposal("code-142", label: "label-114")
        item.status = Consent.ScheduledProxyProposalStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ScheduledProxyProposalStatus.proposed) }
    }
}
