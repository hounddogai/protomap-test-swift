@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationDigestTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newRevocationDigest("code-408", title: "title-938")
        #expect(item.status == Consent.RevocationDigestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newRevocationDigest("code-408", title: "title-938")
        try item.moveTo(Consent.RevocationDigestStatus.scheduled)
        #expect(item.status == Consent.RevocationDigestStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newRevocationDigest("code-408", title: "title-938")
        item.status = Consent.RevocationDigestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RevocationDigestStatus.planned) }
    }
}
