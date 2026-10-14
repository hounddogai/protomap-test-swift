@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultProxyScoreTests {
    @Test func startsInRequested() throws {
        let item = Consent.newDefaultProxyScore("code-353", label: "label-203")
        #expect(item.status == Consent.DefaultProxyScoreStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Consent.newDefaultProxyScore("code-353", label: "label-203")
        try item.moveTo(Consent.DefaultProxyScoreStatus.revoked)
        #expect(item.status == Consent.DefaultProxyScoreStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newDefaultProxyScore("code-353", label: "label-203")
        item.status = Consent.DefaultProxyScoreStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DefaultProxyScoreStatus.requested) }
    }
}
