@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientProxyClaimTests {
    @Test func startsInDraft() throws {
        let item = Consent.newLenientProxyClaim("code-51", name: "name-262")
        #expect(item.status == Consent.LenientProxyClaimStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Consent.newLenientProxyClaim("code-51", name: "name-262")
        try item.moveTo(Consent.LenientProxyClaimStatus.active)
        #expect(item.status == Consent.LenientProxyClaimStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newLenientProxyClaim("code-51", name: "name-262")
        item.status = Consent.LenientProxyClaimStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LenientProxyClaimStatus.draft) }
    }
}
