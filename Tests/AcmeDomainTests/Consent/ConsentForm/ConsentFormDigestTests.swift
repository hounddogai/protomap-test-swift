@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormDigestTests {
    @Test func startsInProposed() throws {
        let item = Consent.newConsentFormDigest("code-534", name: "name-79")
        #expect(item.status == Consent.ConsentFormDigestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Consent.newConsentFormDigest("code-534", name: "name-79")
        try item.moveTo(Consent.ConsentFormDigestStatus.rejected)
        #expect(item.status == Consent.ConsentFormDigestStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newConsentFormDigest("code-534", name: "name-79")
        item.status = Consent.ConsentFormDigestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormDigestStatus.proposed) }
    }
}
