@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalConsentFormTargetTests {
    @Test func startsInDraft() throws {
        let item = Consent.newSeasonalConsentFormTarget("code-353", name: "name-435")
        #expect(item.status == Consent.SeasonalConsentFormTargetStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Consent.newSeasonalConsentFormTarget("code-353", name: "name-435")
        try item.moveTo(Consent.SeasonalConsentFormTargetStatus.active)
        #expect(item.status == Consent.SeasonalConsentFormTargetStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newSeasonalConsentFormTarget("code-353", name: "name-435")
        item.status = Consent.SeasonalConsentFormTargetStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.SeasonalConsentFormTargetStatus.draft) }
    }
}
