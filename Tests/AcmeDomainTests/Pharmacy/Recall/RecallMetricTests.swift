@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallMetricTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newRecallMetric("code-389", name: "name-198")
        #expect(item.status == Pharmacy.RecallMetricStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Pharmacy.newRecallMetric("code-389", name: "name-198")
        try item.moveTo(Pharmacy.RecallMetricStatus.draining)
        #expect(item.status == Pharmacy.RecallMetricStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newRecallMetric("code-389", name: "name-198")
        item.status = Pharmacy.RecallMetricStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallMetricStatus.idle) }
    }
}
