@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedCareGapAssignmentTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newBatchedCareGapAssignment("code-159", title: "title-593")
        #expect(item.status == CareManagement.BatchedCareGapAssignmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = CareManagement.newBatchedCareGapAssignment("code-159", title: "title-593")
        try item.moveTo(CareManagement.BatchedCareGapAssignmentStatus.active)
        #expect(item.status == CareManagement.BatchedCareGapAssignmentStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newBatchedCareGapAssignment("code-159", title: "title-593")
        item.status = CareManagement.BatchedCareGapAssignmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.BatchedCareGapAssignmentStatus.draft) }
    }
}
