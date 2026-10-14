@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedAssessmentScheduleTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newCappedAssessmentSchedule("code-623", label: "label-883")
        #expect(item.status == CareManagement.CappedAssessmentScheduleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = CareManagement.newCappedAssessmentSchedule("code-623", label: "label-883")
        try item.moveTo(CareManagement.CappedAssessmentScheduleStatus.reopened)
        #expect(item.status == CareManagement.CappedAssessmentScheduleStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newCappedAssessmentSchedule("code-623", label: "label-883")
        item.status = CareManagement.CappedAssessmentScheduleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CappedAssessmentScheduleStatus.`open`) }
    }
}
