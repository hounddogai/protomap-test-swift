@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyTieredDispenseMetricTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newTieredDispenseMetric("code-92", label: "label-923")
        #expect(item.status == Pharmacy.TieredDispenseMetricStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Pharmacy.newTieredDispenseMetric("code-92", label: "label-923")
        try item.moveTo(Pharmacy.TieredDispenseMetricStatus.rejected)
        #expect(item.status == Pharmacy.TieredDispenseMetricStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newTieredDispenseMetric("code-92", label: "label-923")
        item.status = Pharmacy.TieredDispenseMetricStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.TieredDispenseMetricStatus.proposed) }
    }
}
