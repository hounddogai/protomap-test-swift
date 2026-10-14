@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningBatchTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newCleaningBatch("code-359", label: "label-469")
        #expect(item.status == BedManagement.CleaningBatchStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = BedManagement.newCleaningBatch("code-359", label: "label-469")
        try item.moveTo(BedManagement.CleaningBatchStatus.withdrawn)
        #expect(item.status == BedManagement.CleaningBatchStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newCleaningBatch("code-359", label: "label-469")
        item.status = BedManagement.CleaningBatchStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningBatchStatus.proposed) }
    }
}
