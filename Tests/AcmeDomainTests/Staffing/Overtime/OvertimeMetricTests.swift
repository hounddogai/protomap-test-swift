@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeMetricTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newOvertimeMetric("code-574", title: "title-663")
        #expect(item.status == Staffing.OvertimeMetricStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Staffing.newOvertimeMetric("code-574", title: "title-663")
        try item.moveTo(Staffing.OvertimeMetricStatus.active)
        #expect(item.status == Staffing.OvertimeMetricStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newOvertimeMetric("code-574", title: "title-663")
        item.status = Staffing.OvertimeMetricStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeMetricStatus.draft) }
    }
}
