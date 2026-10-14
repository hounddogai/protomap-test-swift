@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyTierTests {
    @Test func startsInCreated() throws {
        let item = Consent.newProxyTier("code-981", name: "name-262")
        #expect(item.status == Consent.ProxyTierStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Consent.newProxyTier("code-981", name: "name-262")
        try item.moveTo(Consent.ProxyTierStatus.retired)
        #expect(item.status == Consent.ProxyTierStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newProxyTier("code-981", name: "name-262")
        item.status = Consent.ProxyTierStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyTierStatus.created) }
    }
}
