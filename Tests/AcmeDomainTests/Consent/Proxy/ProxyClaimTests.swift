@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyClaimTests {
    @Test func startsInRequested() throws {
        let item = Consent.newProxyClaim("code-594", title: "title-282")
        #expect(item.status == Consent.ProxyClaimStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newProxyClaim("code-594", title: "title-282")
        try item.moveTo(Consent.ProxyClaimStatus.granted)
        #expect(item.status == Consent.ProxyClaimStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newProxyClaim("code-594", title: "title-282")
        item.status = Consent.ProxyClaimStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyClaimStatus.requested) }
    }
}
