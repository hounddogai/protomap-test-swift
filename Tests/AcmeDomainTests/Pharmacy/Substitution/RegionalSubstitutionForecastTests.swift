@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalSubstitutionForecastTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newRegionalSubstitutionForecast("code-147", name: "name-155")
        #expect(item.status == Pharmacy.RegionalSubstitutionForecastStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Pharmacy.newRegionalSubstitutionForecast("code-147", name: "name-155")
        try item.moveTo(Pharmacy.RegionalSubstitutionForecastStatus.scheduled)
        #expect(item.status == Pharmacy.RegionalSubstitutionForecastStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newRegionalSubstitutionForecast("code-147", name: "name-155")
        item.status = Pharmacy.RegionalSubstitutionForecastStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RegionalSubstitutionForecastStatus.planned) }
    }
}
