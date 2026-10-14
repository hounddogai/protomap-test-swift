@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingLanguageForecastTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newRollingLanguageForecast("code-785", label: "label-800")
        #expect(item.status == Consent.RollingLanguageForecastStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newRollingLanguageForecast("code-785", label: "label-800")
        try item.moveTo(Consent.RollingLanguageForecastStatus.scheduled)
        #expect(item.status == Consent.RollingLanguageForecastStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newRollingLanguageForecast("code-785", label: "label-800")
        item.status = Consent.RollingLanguageForecastStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RollingLanguageForecastStatus.planned) }
    }
}
