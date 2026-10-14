@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyBaselineTests {
    @Test func startsInOpen() throws {
        let item = Consent.newProxyBaseline("code-493", name: "name-679")
        #expect(item.status == Consent.ProxyBaselineStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Consent.newProxyBaseline("code-493", name: "name-679")
        try item.moveTo(Consent.ProxyBaselineStatus.reopened)
        #expect(item.status == Consent.ProxyBaselineStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newProxyBaseline("code-493", name: "name-679")
        item.status = Consent.ProxyBaselineStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyBaselineStatus.`open`) }
    }
}
