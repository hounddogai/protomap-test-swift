@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryProxyBaselineTests {
    @Test func startsInNew() throws {
        let item = Consent.newPrimaryProxyBaseline("code-765", name: "name-38")
        #expect(item.status == Consent.PrimaryProxyBaselineStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Consent.newPrimaryProxyBaseline("code-765", name: "name-38")
        try item.moveTo(Consent.PrimaryProxyBaselineStatus.queued)
        #expect(item.status == Consent.PrimaryProxyBaselineStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newPrimaryProxyBaseline("code-765", name: "name-38")
        item.status = Consent.PrimaryProxyBaselineStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.PrimaryProxyBaselineStatus.new) }
    }
}
