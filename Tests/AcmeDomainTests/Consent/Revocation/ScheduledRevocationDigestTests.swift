@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledRevocationDigestTests {
    @Test func startsInDraft() throws {
        let item = Consent.newScheduledRevocationDigest("code-300", name: "name-170")
        #expect(item.status == Consent.ScheduledRevocationDigestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Consent.newScheduledRevocationDigest("code-300", name: "name-170")
        try item.moveTo(Consent.ScheduledRevocationDigestStatus.closed)
        #expect(item.status == Consent.ScheduledRevocationDigestStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newScheduledRevocationDigest("code-300", name: "name-170")
        item.status = Consent.ScheduledRevocationDigestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ScheduledRevocationDigestStatus.draft) }
    }
}
