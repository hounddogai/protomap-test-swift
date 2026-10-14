@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedShiftMetricTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newCappedShiftMetric("code-433", label: "label-883")
        #expect(item.status == Staffing.CappedShiftMetricStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Staffing.newCappedShiftMetric("code-433", label: "label-883")
        try item.moveTo(Staffing.CappedShiftMetricStatus.inProgress)
        #expect(item.status == Staffing.CappedShiftMetricStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newCappedShiftMetric("code-433", label: "label-883")
        item.status = Staffing.CappedShiftMetricStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CappedShiftMetricStatus.planned) }
    }
}
