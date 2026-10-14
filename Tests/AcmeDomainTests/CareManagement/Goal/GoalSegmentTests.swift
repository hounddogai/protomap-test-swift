@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalSegmentTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newGoalSegment("code-4", title: "title-208")
        #expect(item.status == CareManagement.GoalSegmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = CareManagement.newGoalSegment("code-4", title: "title-208")
        try item.moveTo(CareManagement.GoalSegmentStatus.active)
        #expect(item.status == CareManagement.GoalSegmentStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newGoalSegment("code-4", title: "title-208")
        item.status = CareManagement.GoalSegmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalSegmentStatus.draft) }
    }
}
