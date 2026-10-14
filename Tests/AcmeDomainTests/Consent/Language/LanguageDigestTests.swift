@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageDigestTests {
    @Test func startsInIdle() throws {
        let item = Consent.newLanguageDigest("code-389", name: "name-861")
        #expect(item.status == Consent.LanguageDigestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Consent.newLanguageDigest("code-389", name: "name-861")
        try item.moveTo(Consent.LanguageDigestStatus.warming)
        #expect(item.status == Consent.LanguageDigestStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newLanguageDigest("code-389", name: "name-861")
        item.status = Consent.LanguageDigestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageDigestStatus.idle) }
    }
}
