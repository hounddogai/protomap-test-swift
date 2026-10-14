@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyPolicyTests {
    @Test func startsInRequested() throws {
        let item = Consent.newProxyPolicy("code-219", label: "label-161")
        #expect(item.status == Consent.ProxyPolicyStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Consent.newProxyPolicy("code-219", label: "label-161")
        try item.moveTo(Consent.ProxyPolicyStatus.revoked)
        #expect(item.status == Consent.ProxyPolicyStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newProxyPolicy("code-219", label: "label-161")
        item.status = Consent.ProxyPolicyStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyPolicyStatus.requested) }
    }
}
