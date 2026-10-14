@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingCareGapDraftTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newPendingCareGapDraft("code-588", name: "name-369")
        #expect(item.status == CareManagement.PendingCareGapDraftStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = CareManagement.newPendingCareGapDraft("code-588", name: "name-369")
        try item.moveTo(CareManagement.PendingCareGapDraftStatus.inProgress)
        #expect(item.status == CareManagement.PendingCareGapDraftStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newPendingCareGapDraft("code-588", name: "name-369")
        item.status = CareManagement.PendingCareGapDraftStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PendingCareGapDraftStatus.planned) }
    }
}
