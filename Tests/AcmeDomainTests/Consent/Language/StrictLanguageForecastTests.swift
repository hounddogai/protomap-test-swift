@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictLanguageForecastTests {
    @Test func startsInProposed() throws {
        let item = Consent.newStrictLanguageForecast("code-721", title: "title-814")
        #expect(item.status == Consent.StrictLanguageForecastStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Consent.newStrictLanguageForecast("code-721", title: "title-814")
        try item.moveTo(Consent.StrictLanguageForecastStatus.withdrawn)
        #expect(item.status == Consent.StrictLanguageForecastStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newStrictLanguageForecast("code-721", title: "title-814")
        item.status = Consent.StrictLanguageForecastStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.StrictLanguageForecastStatus.proposed) }
    }
}
