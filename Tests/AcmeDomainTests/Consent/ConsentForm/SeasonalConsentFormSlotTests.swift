@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalConsentFormSlotTests {
    @Test func startsInOpen() throws {
        let item = Consent.newSeasonalConsentFormSlot("code-776", label: "label-825")
        #expect(item.status == Consent.SeasonalConsentFormSlotStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Consent.newSeasonalConsentFormSlot("code-776", label: "label-825")
        try item.moveTo(Consent.SeasonalConsentFormSlotStatus.reopened)
        #expect(item.status == Consent.SeasonalConsentFormSlotStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newSeasonalConsentFormSlot("code-776", label: "label-825")
        item.status = Consent.SeasonalConsentFormSlotStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.SeasonalConsentFormSlotStatus.`open`) }
    }
}
