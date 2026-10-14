@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionMetricTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newInteractionMetric("code-673", name: "name-552")
        #expect(item.status == Pharmacy.InteractionMetricStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Pharmacy.newInteractionMetric("code-673", name: "name-552")
        try item.moveTo(Pharmacy.InteractionMetricStatus.draining)
        #expect(item.status == Pharmacy.InteractionMetricStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newInteractionMetric("code-673", name: "name-552")
        item.status = Pharmacy.InteractionMetricStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionMetricStatus.idle) }
    }
}
