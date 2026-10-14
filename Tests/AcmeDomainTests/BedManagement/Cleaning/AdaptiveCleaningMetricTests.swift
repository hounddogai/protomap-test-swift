@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveCleaningMetricTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newAdaptiveCleaningMetric("code-120", name: "name-750")
        #expect(item.status == BedManagement.AdaptiveCleaningMetricStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = BedManagement.newAdaptiveCleaningMetric("code-120", name: "name-750")
        try item.moveTo(BedManagement.AdaptiveCleaningMetricStatus.ready)
        #expect(item.status == BedManagement.AdaptiveCleaningMetricStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newAdaptiveCleaningMetric("code-120", name: "name-750")
        item.status = BedManagement.AdaptiveCleaningMetricStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.AdaptiveCleaningMetricStatus.idle) }
    }
}
