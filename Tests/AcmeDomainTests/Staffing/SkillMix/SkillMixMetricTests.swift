@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixMetricTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newSkillMixMetric("code-4", title: "title-999")
        #expect(item.status == Staffing.SkillMixMetricStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newSkillMixMetric("code-4", title: "title-999")
        try item.moveTo(Staffing.SkillMixMetricStatus.rejected)
        #expect(item.status == Staffing.SkillMixMetricStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newSkillMixMetric("code-4", title: "title-999")
        item.status = Staffing.SkillMixMetricStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixMetricStatus.proposed) }
    }
}
