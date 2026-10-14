@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultProxyProposalTests {
    @Test func startsInIdle() throws {
        let item = Consent.newDefaultProxyProposal("code-503", label: "label-460")
        #expect(item.status == Consent.DefaultProxyProposalStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Consent.newDefaultProxyProposal("code-503", label: "label-460")
        try item.moveTo(Consent.DefaultProxyProposalStatus.warming)
        #expect(item.status == Consent.DefaultProxyProposalStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newDefaultProxyProposal("code-503", label: "label-460")
        item.status = Consent.DefaultProxyProposalStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DefaultProxyProposalStatus.idle) }
    }
}
