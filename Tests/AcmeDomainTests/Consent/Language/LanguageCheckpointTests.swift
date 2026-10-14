@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageCheckpointTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newLanguageCheckpoint("code-173", name: "name-734")
        #expect(item.status == Consent.LanguageCheckpointStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newLanguageCheckpoint("code-173", name: "name-734")
        try item.moveTo(Consent.LanguageCheckpointStatus.scheduled)
        #expect(item.status == Consent.LanguageCheckpointStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newLanguageCheckpoint("code-173", name: "name-734")
        item.status = Consent.LanguageCheckpointStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageCheckpointStatus.planned) }
    }
}
