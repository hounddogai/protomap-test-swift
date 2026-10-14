@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapTargetTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newCareGapTarget("code-467", name: "name-295")
        #expect(item.status == CareManagement.CareGapTargetStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = CareManagement.newCareGapTarget("code-467", name: "name-295")
        try item.moveTo(CareManagement.CareGapTargetStatus.pending)
        #expect(item.status == CareManagement.CareGapTargetStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newCareGapTarget("code-467", name: "name-295")
        item.status = CareManagement.CareGapTargetStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapTargetStatus.draft) }
    }
}
