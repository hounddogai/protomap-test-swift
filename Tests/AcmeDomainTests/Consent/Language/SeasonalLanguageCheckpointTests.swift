@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalLanguageCheckpointTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newSeasonalLanguageCheckpoint("code-121", title: "title-763")
        #expect(item.status == Consent.SeasonalLanguageCheckpointStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newSeasonalLanguageCheckpoint("code-121", title: "title-763")
        try item.moveTo(Consent.SeasonalLanguageCheckpointStatus.scheduled)
        #expect(item.status == Consent.SeasonalLanguageCheckpointStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newSeasonalLanguageCheckpoint("code-121", title: "title-763")
        item.status = Consent.SeasonalLanguageCheckpointStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.SeasonalLanguageCheckpointStatus.planned) }
    }
}
