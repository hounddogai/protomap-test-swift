@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientLanguageCheckpointTests {
    @Test func startsInRequested() throws {
        let item = Consent.newLenientLanguageCheckpoint("code-99", title: "title-455")
        #expect(item.status == Consent.LenientLanguageCheckpointStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Consent.newLenientLanguageCheckpoint("code-99", title: "title-455")
        try item.moveTo(Consent.LenientLanguageCheckpointStatus.revoked)
        #expect(item.status == Consent.LenientLanguageCheckpointStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newLenientLanguageCheckpoint("code-99", title: "title-455")
        item.status = Consent.LenientLanguageCheckpointStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LenientLanguageCheckpointStatus.requested) }
    }
}
