@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedDischargePlanDraftTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newBatchedDischargePlanDraft("code-521", name: "name-944")
        #expect(item.status == BedManagement.BatchedDischargePlanDraftStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = BedManagement.newBatchedDischargePlanDraft("code-521", name: "name-944")
        try item.moveTo(BedManagement.BatchedDischargePlanDraftStatus.inReview)
        #expect(item.status == BedManagement.BatchedDischargePlanDraftStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newBatchedDischargePlanDraft("code-521", name: "name-944")
        item.status = BedManagement.BatchedDischargePlanDraftStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BatchedDischargePlanDraftStatus.`open`) }
    }
}
