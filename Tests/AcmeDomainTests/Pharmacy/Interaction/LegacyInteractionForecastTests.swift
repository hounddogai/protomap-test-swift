@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyInteractionForecastTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newLegacyInteractionForecast("code-596", title: "title-988")
        #expect(item.status == Pharmacy.LegacyInteractionForecastStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Pharmacy.newLegacyInteractionForecast("code-596", title: "title-988")
        try item.moveTo(Pharmacy.LegacyInteractionForecastStatus.inProgress)
        #expect(item.status == Pharmacy.LegacyInteractionForecastStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newLegacyInteractionForecast("code-596", title: "title-988")
        item.status = Pharmacy.LegacyInteractionForecastStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LegacyInteractionForecastStatus.planned) }
    }
}
