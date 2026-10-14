@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalWitnessGroupTests {
    @Test func startsInDraft() throws {
        let item = Consent.newSeasonalWitnessGroup("code-719", name: "name-583")
        #expect(item.status == Consent.SeasonalWitnessGroupStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Consent.newSeasonalWitnessGroup("code-719", name: "name-583")
        try item.moveTo(Consent.SeasonalWitnessGroupStatus.active)
        #expect(item.status == Consent.SeasonalWitnessGroupStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newSeasonalWitnessGroup("code-719", name: "name-583")
        item.status = Consent.SeasonalWitnessGroupStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.SeasonalWitnessGroupStatus.draft) }
    }
}
