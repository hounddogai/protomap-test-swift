@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyIsolationMetricTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newLegacyIsolationMetric("code-547", name: "name-94")
        #expect(item.status == BedManagement.LegacyIsolationMetricStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = BedManagement.newLegacyIsolationMetric("code-547", name: "name-94")
        try item.moveTo(BedManagement.LegacyIsolationMetricStatus.granted)
        #expect(item.status == BedManagement.LegacyIsolationMetricStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newLegacyIsolationMetric("code-547", name: "name-94")
        item.status = BedManagement.LegacyIsolationMetricStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LegacyIsolationMetricStatus.requested) }
    }
}
