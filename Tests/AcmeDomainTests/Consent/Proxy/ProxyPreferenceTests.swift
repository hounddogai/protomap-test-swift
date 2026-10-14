@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyPreferenceTests {
    @Test func startsInOpen() throws {
        let item = Consent.newProxyPreference("code-336", title: "title-324")
        #expect(item.status == Consent.ProxyPreferenceStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Consent.newProxyPreference("code-336", title: "title-324")
        try item.moveTo(Consent.ProxyPreferenceStatus.reopened)
        #expect(item.status == Consent.ProxyPreferenceStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newProxyPreference("code-336", title: "title-324")
        item.status = Consent.ProxyPreferenceStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyPreferenceStatus.`open`) }
    }
}
