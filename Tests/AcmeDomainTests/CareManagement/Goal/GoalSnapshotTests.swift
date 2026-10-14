@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalSnapshotTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newGoalSnapshot("code-401", label: "label-899")
        #expect(item.status == CareManagement.GoalSnapshotStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = CareManagement.newGoalSnapshot("code-401", label: "label-899")
        try item.moveTo(CareManagement.GoalSnapshotStatus.pending)
        #expect(item.status == CareManagement.GoalSnapshotStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newGoalSnapshot("code-401", label: "label-899")
        item.status = CareManagement.GoalSnapshotStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalSnapshotStatus.draft) }
    }
}
