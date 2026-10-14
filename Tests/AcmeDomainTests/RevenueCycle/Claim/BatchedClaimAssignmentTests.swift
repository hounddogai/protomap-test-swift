@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedClaimAssignmentTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newBatchedClaimAssignment("code-110", title: "title-76")
        #expect(item.status == RevenueCycle.BatchedClaimAssignmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = RevenueCycle.newBatchedClaimAssignment("code-110", title: "title-76")
        try item.moveTo(RevenueCycle.BatchedClaimAssignmentStatus.inProgress)
        #expect(item.status == RevenueCycle.BatchedClaimAssignmentStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newBatchedClaimAssignment("code-110", title: "title-76")
        item.status = RevenueCycle.BatchedClaimAssignmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.BatchedClaimAssignmentStatus.planned) }
    }
}
