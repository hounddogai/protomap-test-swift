@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryCleaningBatchTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newPrimaryCleaningBatch("code-914", name: "name-354")
        #expect(item.status == BedManagement.PrimaryCleaningBatchStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = BedManagement.newPrimaryCleaningBatch("code-914", name: "name-354")
        try item.moveTo(BedManagement.PrimaryCleaningBatchStatus.scheduled)
        #expect(item.status == BedManagement.PrimaryCleaningBatchStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newPrimaryCleaningBatch("code-914", name: "name-354")
        item.status = BedManagement.PrimaryCleaningBatchStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PrimaryCleaningBatchStatus.planned) }
    }
}
