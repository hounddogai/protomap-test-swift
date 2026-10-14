@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryForecastTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newInventoryForecast("code-925", label: "label-576")
        #expect(item.status == Pharmacy.InventoryForecastStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newInventoryForecast("code-925", label: "label-576")
        try item.moveTo(Pharmacy.InventoryForecastStatus.approved)
        #expect(item.status == Pharmacy.InventoryForecastStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newInventoryForecast("code-925", label: "label-576")
        item.status = Pharmacy.InventoryForecastStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryForecastStatus.proposed) }
    }
}
