@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalInteractionForecastTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newRegionalInteractionForecast("code-279", name: "name-697")
        #expect(item.status == Pharmacy.RegionalInteractionForecastStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Pharmacy.newRegionalInteractionForecast("code-279", name: "name-697")
        try item.moveTo(Pharmacy.RegionalInteractionForecastStatus.cancelled)
        #expect(item.status == Pharmacy.RegionalInteractionForecastStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newRegionalInteractionForecast("code-279", name: "name-697")
        item.status = Pharmacy.RegionalInteractionForecastStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RegionalInteractionForecastStatus.planned) }
    }
}
