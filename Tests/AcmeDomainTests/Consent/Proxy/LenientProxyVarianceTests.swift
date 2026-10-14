@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientProxyVarianceTests {
    @Test func startsInProposed() throws {
        let item = Consent.newLenientProxyVariance("code-291", name: "name-748")
        #expect(item.status == Consent.LenientProxyVarianceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Consent.newLenientProxyVariance("code-291", name: "name-748")
        try item.moveTo(Consent.LenientProxyVarianceStatus.rejected)
        #expect(item.status == Consent.LenientProxyVarianceStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newLenientProxyVariance("code-291", name: "name-748")
        item.status = Consent.LenientProxyVarianceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LenientProxyVarianceStatus.proposed) }
    }
}
