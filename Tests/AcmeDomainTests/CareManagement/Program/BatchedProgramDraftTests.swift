@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedProgramDraftTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newBatchedProgramDraft("code-796", title: "title-171")
        #expect(item.status == CareManagement.BatchedProgramDraftStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newBatchedProgramDraft("code-796", title: "title-171")
        try item.moveTo(CareManagement.BatchedProgramDraftStatus.granted)
        #expect(item.status == CareManagement.BatchedProgramDraftStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newBatchedProgramDraft("code-796", title: "title-171")
        item.status = CareManagement.BatchedProgramDraftStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.BatchedProgramDraftStatus.requested) }
    }
}
