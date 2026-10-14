@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalConsentFormWindowTests {
    @Test func startsInRequested() throws {
        let item = Consent.newSeasonalConsentFormWindow("code-362", title: "title-429")
        #expect(item.status == Consent.SeasonalConsentFormWindowStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newSeasonalConsentFormWindow("code-362", title: "title-429")
        try item.moveTo(Consent.SeasonalConsentFormWindowStatus.granted)
        #expect(item.status == Consent.SeasonalConsentFormWindowStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newSeasonalConsentFormWindow("code-362", title: "title-429")
        item.status = Consent.SeasonalConsentFormWindowStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.SeasonalConsentFormWindowStatus.requested) }
    }
}
