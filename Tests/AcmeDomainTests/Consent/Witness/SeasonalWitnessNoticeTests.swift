@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalWitnessNoticeTests {
    @Test func startsInDraft() throws {
        let item = Consent.newSeasonalWitnessNotice("code-894", name: "name-645")
        #expect(item.status == Consent.SeasonalWitnessNoticeStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Consent.newSeasonalWitnessNotice("code-894", name: "name-645")
        try item.moveTo(Consent.SeasonalWitnessNoticeStatus.active)
        #expect(item.status == Consent.SeasonalWitnessNoticeStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newSeasonalWitnessNotice("code-894", name: "name-645")
        item.status = Consent.SeasonalWitnessNoticeStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.SeasonalWitnessNoticeStatus.draft) }
    }
}
