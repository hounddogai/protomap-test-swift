@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingGoalSnapshotTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newPendingGoalSnapshot("code-428", name: "name-65")
        #expect(item.status == CareManagement.PendingGoalSnapshotStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = CareManagement.newPendingGoalSnapshot("code-428", name: "name-65")
        try item.moveTo(CareManagement.PendingGoalSnapshotStatus.scheduled)
        #expect(item.status == CareManagement.PendingGoalSnapshotStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newPendingGoalSnapshot("code-428", name: "name-65")
        item.status = CareManagement.PendingGoalSnapshotStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PendingGoalSnapshotStatus.planned) }
    }
}
