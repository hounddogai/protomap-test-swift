@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyOverrideTests {
    @Test func startsInOpen() throws {
        let item = Consent.newProxyOverride("code-282", name: "name-145")
        #expect(item.status == Consent.ProxyOverrideStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Consent.newProxyOverride("code-282", name: "name-145")
        try item.moveTo(Consent.ProxyOverrideStatus.inReview)
        #expect(item.status == Consent.ProxyOverrideStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newProxyOverride("code-282", name: "name-145")
        item.status = Consent.ProxyOverrideStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyOverrideStatus.`open`) }
    }
}
