@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyTieredRecallMetricTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newTieredRecallMetric("code-926", name: "name-207")
        #expect(item.status == Pharmacy.TieredRecallMetricStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Pharmacy.newTieredRecallMetric("code-926", name: "name-207")
        try item.moveTo(Pharmacy.TieredRecallMetricStatus.retired)
        #expect(item.status == Pharmacy.TieredRecallMetricStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newTieredRecallMetric("code-926", name: "name-207")
        item.status = Pharmacy.TieredRecallMetricStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.TieredRecallMetricStatus.created) }
    }
}
