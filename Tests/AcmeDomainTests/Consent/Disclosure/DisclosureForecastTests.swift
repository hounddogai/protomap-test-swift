@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureForecastTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newDisclosureForecast("code-311", title: "title-219")
        #expect(item.status == Consent.DisclosureForecastStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newDisclosureForecast("code-311", title: "title-219")
        try item.moveTo(Consent.DisclosureForecastStatus.scheduled)
        #expect(item.status == Consent.DisclosureForecastStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newDisclosureForecast("code-311", title: "title-219")
        item.status = Consent.DisclosureForecastStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureForecastStatus.planned) }
    }
}
