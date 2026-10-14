@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingOvertimeMetricTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newPendingOvertimeMetric("code-953", name: "name-839")
        #expect(item.status == Staffing.PendingOvertimeMetricStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Staffing.newPendingOvertimeMetric("code-953", name: "name-839")
        try item.moveTo(Staffing.PendingOvertimeMetricStatus.reopened)
        #expect(item.status == Staffing.PendingOvertimeMetricStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newPendingOvertimeMetric("code-953", name: "name-839")
        item.status = Staffing.PendingOvertimeMetricStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PendingOvertimeMetricStatus.`open`) }
    }
}
