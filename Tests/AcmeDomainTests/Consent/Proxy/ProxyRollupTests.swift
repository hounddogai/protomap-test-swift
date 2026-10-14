@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyRollupTests {
    @Test func startsInCreated() throws {
        let item = Consent.newProxyRollup("code-552", name: "name-927")
        #expect(item.status == Consent.ProxyRollupStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Consent.newProxyRollup("code-552", name: "name-927")
        try item.moveTo(Consent.ProxyRollupStatus.published)
        #expect(item.status == Consent.ProxyRollupStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newProxyRollup("code-552", name: "name-927")
        item.status = Consent.ProxyRollupStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyRollupStatus.created) }
    }
}
