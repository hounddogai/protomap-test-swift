@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultProxyClaimTests {
    @Test func startsInCreated() throws {
        let item = Consent.newDefaultProxyClaim("code-398", name: "name-611")
        #expect(item.status == Consent.DefaultProxyClaimStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newDefaultProxyClaim("code-398", name: "name-611")
        try item.moveTo(Consent.DefaultProxyClaimStatus.validated)
        #expect(item.status == Consent.DefaultProxyClaimStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newDefaultProxyClaim("code-398", name: "name-611")
        item.status = Consent.DefaultProxyClaimStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DefaultProxyClaimStatus.created) }
    }
}
