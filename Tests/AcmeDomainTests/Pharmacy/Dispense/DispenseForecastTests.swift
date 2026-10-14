@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseForecastTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newDispenseForecast("code-229", name: "name-48")
        #expect(item.status == Pharmacy.DispenseForecastStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Pharmacy.newDispenseForecast("code-229", name: "name-48")
        try item.moveTo(Pharmacy.DispenseForecastStatus.withdrawn)
        #expect(item.status == Pharmacy.DispenseForecastStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newDispenseForecast("code-229", name: "name-48")
        item.status = Pharmacy.DispenseForecastStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseForecastStatus.proposed) }
    }
}
