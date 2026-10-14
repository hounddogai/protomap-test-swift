@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedProxyProposalTests {
    @Test func startsInRequested() throws {
        let item = Consent.newCappedProxyProposal("code-883", name: "name-331")
        #expect(item.status == Consent.CappedProxyProposalStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newCappedProxyProposal("code-883", name: "name-331")
        try item.moveTo(Consent.CappedProxyProposalStatus.granted)
        #expect(item.status == Consent.CappedProxyProposalStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newCappedProxyProposal("code-883", name: "name-331")
        item.status = Consent.CappedProxyProposalStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.CappedProxyProposalStatus.requested) }
    }
}
