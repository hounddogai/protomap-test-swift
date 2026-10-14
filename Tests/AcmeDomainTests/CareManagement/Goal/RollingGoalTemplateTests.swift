@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingGoalTemplateTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newRollingGoalTemplate("code-798", label: "label-668")
        #expect(item.status == CareManagement.RollingGoalTemplateStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = CareManagement.newRollingGoalTemplate("code-798", label: "label-668")
        try item.moveTo(CareManagement.RollingGoalTemplateStatus.completed)
        #expect(item.status == CareManagement.RollingGoalTemplateStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newRollingGoalTemplate("code-798", label: "label-668")
        item.status = CareManagement.RollingGoalTemplateStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RollingGoalTemplateStatus.planned) }
    }
}
