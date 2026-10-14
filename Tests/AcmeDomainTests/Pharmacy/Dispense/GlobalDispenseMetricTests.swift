@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalDispenseMetricTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newGlobalDispenseMetric("code-482", name: "name-735")
        #expect(item.status == Pharmacy.GlobalDispenseMetricStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Pharmacy.newGlobalDispenseMetric("code-482", name: "name-735")
        try item.moveTo(Pharmacy.GlobalDispenseMetricStatus.ready)
        #expect(item.status == Pharmacy.GlobalDispenseMetricStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newGlobalDispenseMetric("code-482", name: "name-735")
        item.status = Pharmacy.GlobalDispenseMetricStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.GlobalDispenseMetricStatus.idle) }
    }
}
