@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalDraftTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newGoalDraft("code-118", label: "label-627")
        #expect(item.status == CareManagement.GoalDraftStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = CareManagement.newGoalDraft("code-118", label: "label-627")
        try item.moveTo(CareManagement.GoalDraftStatus.validated)
        #expect(item.status == CareManagement.GoalDraftStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newGoalDraft("code-118", label: "label-627")
        item.status = CareManagement.GoalDraftStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalDraftStatus.created) }
    }
}
