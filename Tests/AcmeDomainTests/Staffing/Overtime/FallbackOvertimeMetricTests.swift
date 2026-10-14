@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackOvertimeMetricTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newFallbackOvertimeMetric("code-999", name: "name-351")
        #expect(item.status == Staffing.FallbackOvertimeMetricStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Staffing.newFallbackOvertimeMetric("code-999", name: "name-351")
        try item.moveTo(Staffing.FallbackOvertimeMetricStatus.inReview)
        #expect(item.status == Staffing.FallbackOvertimeMetricStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newFallbackOvertimeMetric("code-999", name: "name-351")
        item.status = Staffing.FallbackOvertimeMetricStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FallbackOvertimeMetricStatus.`open`) }
    }
}
