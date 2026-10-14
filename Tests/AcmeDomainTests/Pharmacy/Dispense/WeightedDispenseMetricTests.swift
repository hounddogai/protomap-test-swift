@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedDispenseMetricTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newWeightedDispenseMetric("code-854", name: "name-703")
        #expect(item.status == Pharmacy.WeightedDispenseMetricStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Pharmacy.newWeightedDispenseMetric("code-854", name: "name-703")
        try item.moveTo(Pharmacy.WeightedDispenseMetricStatus.queued)
        #expect(item.status == Pharmacy.WeightedDispenseMetricStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newWeightedDispenseMetric("code-854", name: "name-703")
        item.status = Pharmacy.WeightedDispenseMetricStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.WeightedDispenseMetricStatus.new) }
    }
}
