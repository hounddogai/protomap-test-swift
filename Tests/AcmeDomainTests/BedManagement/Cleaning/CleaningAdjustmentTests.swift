@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningAdjustmentTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newCleaningAdjustment("code-927", label: "label-937")
        #expect(item.status == BedManagement.CleaningAdjustmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = BedManagement.newCleaningAdjustment("code-927", label: "label-937")
        try item.moveTo(BedManagement.CleaningAdjustmentStatus.pending)
        #expect(item.status == BedManagement.CleaningAdjustmentStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newCleaningAdjustment("code-927", label: "label-937")
        item.status = BedManagement.CleaningAdjustmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningAdjustmentStatus.draft) }
    }
}
