@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCleaningQuotaTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newScheduledCleaningQuota("code-751", name: "name-72")
        #expect(item.status == BedManagement.ScheduledCleaningQuotaStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = BedManagement.newScheduledCleaningQuota("code-751", name: "name-72")
        try item.moveTo(BedManagement.ScheduledCleaningQuotaStatus.pending)
        #expect(item.status == BedManagement.ScheduledCleaningQuotaStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newScheduledCleaningQuota("code-751", name: "name-72")
        item.status = BedManagement.ScheduledCleaningQuotaStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ScheduledCleaningQuotaStatus.draft) }
    }
}
