@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryMetricTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newInventoryMetric("code-594", title: "title-552")
        #expect(item.status == Pharmacy.InventoryMetricStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Pharmacy.newInventoryMetric("code-594", title: "title-552")
        try item.moveTo(Pharmacy.InventoryMetricStatus.inProgress)
        #expect(item.status == Pharmacy.InventoryMetricStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newInventoryMetric("code-594", title: "title-552")
        item.status = Pharmacy.InventoryMetricStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryMetricStatus.planned) }
    }
}
