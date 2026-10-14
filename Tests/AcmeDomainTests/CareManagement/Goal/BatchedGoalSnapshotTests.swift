@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedGoalSnapshotTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newBatchedGoalSnapshot("code-384", title: "title-815")
        #expect(item.status == CareManagement.BatchedGoalSnapshotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = CareManagement.newBatchedGoalSnapshot("code-384", title: "title-815")
        try item.moveTo(CareManagement.BatchedGoalSnapshotStatus.queued)
        #expect(item.status == CareManagement.BatchedGoalSnapshotStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newBatchedGoalSnapshot("code-384", title: "title-815")
        item.status = CareManagement.BatchedGoalSnapshotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.BatchedGoalSnapshotStatus.new) }
    }
}
