@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftMetricTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newShiftMetric("code-613", label: "label-449")
        #expect(item.status == Staffing.ShiftMetricStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Staffing.newShiftMetric("code-613", label: "label-449")
        try item.moveTo(Staffing.ShiftMetricStatus.warming)
        #expect(item.status == Staffing.ShiftMetricStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newShiftMetric("code-613", label: "label-449")
        item.status = Staffing.ShiftMetricStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftMetricStatus.idle) }
    }
}
