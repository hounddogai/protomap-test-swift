@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackInventoryForecastTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newFallbackInventoryForecast("code-656", name: "name-635")
        #expect(item.status == Pharmacy.FallbackInventoryForecastStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Pharmacy.newFallbackInventoryForecast("code-656", name: "name-635")
        try item.moveTo(Pharmacy.FallbackInventoryForecastStatus.completed)
        #expect(item.status == Pharmacy.FallbackInventoryForecastStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newFallbackInventoryForecast("code-656", name: "name-635")
        item.status = Pharmacy.FallbackInventoryForecastStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FallbackInventoryForecastStatus.planned) }
    }
}
