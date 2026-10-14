@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedOutreachCycleTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newBatchedOutreachCycle("code-377", title: "title-599")
        #expect(item.status == CareManagement.BatchedOutreachCycleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = CareManagement.newBatchedOutreachCycle("code-377", title: "title-599")
        try item.moveTo(CareManagement.BatchedOutreachCycleStatus.pending)
        #expect(item.status == CareManagement.BatchedOutreachCycleStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newBatchedOutreachCycle("code-377", title: "title-599")
        item.status = CareManagement.BatchedOutreachCycleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.BatchedOutreachCycleStatus.draft) }
    }
}
