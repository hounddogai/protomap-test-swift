@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedProgramWindowTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newBatchedProgramWindow("code-349", title: "title-98")
        #expect(item.status == CareManagement.BatchedProgramWindowStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = CareManagement.newBatchedProgramWindow("code-349", title: "title-98")
        try item.moveTo(CareManagement.BatchedProgramWindowStatus.active)
        #expect(item.status == CareManagement.BatchedProgramWindowStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newBatchedProgramWindow("code-349", title: "title-98")
        item.status = CareManagement.BatchedProgramWindowStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.BatchedProgramWindowStatus.draft) }
    }
}
