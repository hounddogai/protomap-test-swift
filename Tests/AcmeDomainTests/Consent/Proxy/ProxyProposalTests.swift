@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyProposalTests {
    @Test func startsInOpen() throws {
        let item = Consent.newProxyProposal("code-336", name: "name-159")
        #expect(item.status == Consent.ProxyProposalStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Consent.newProxyProposal("code-336", name: "name-159")
        try item.moveTo(Consent.ProxyProposalStatus.archived)
        #expect(item.status == Consent.ProxyProposalStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newProxyProposal("code-336", name: "name-159")
        item.status = Consent.ProxyProposalStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyProposalStatus.`open`) }
    }
}
