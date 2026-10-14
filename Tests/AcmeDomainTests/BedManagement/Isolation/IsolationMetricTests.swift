@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationMetricTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newIsolationMetric("code-432", name: "name-9")
        #expect(item.status == BedManagement.IsolationMetricStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = BedManagement.newIsolationMetric("code-432", name: "name-9")
        try item.moveTo(BedManagement.IsolationMetricStatus.ready)
        #expect(item.status == BedManagement.IsolationMetricStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newIsolationMetric("code-432", name: "name-9")
        item.status = BedManagement.IsolationMetricStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationMetricStatus.idle) }
    }
}
