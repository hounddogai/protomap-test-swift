@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolMetricTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newFloatPoolMetric("code-167", title: "title-967")
        #expect(item.status == Staffing.FloatPoolMetricStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newFloatPoolMetric("code-167", title: "title-967")
        try item.moveTo(Staffing.FloatPoolMetricStatus.rejected)
        #expect(item.status == Staffing.FloatPoolMetricStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newFloatPoolMetric("code-167", title: "title-967")
        item.status = Staffing.FloatPoolMetricStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolMetricStatus.proposed) }
    }
}
