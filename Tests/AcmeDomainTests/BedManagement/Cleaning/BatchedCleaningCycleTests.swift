@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedCleaningCycleTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newBatchedCleaningCycle("code-335", title: "title-123")
        #expect(item.status == BedManagement.BatchedCleaningCycleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = BedManagement.newBatchedCleaningCycle("code-335", title: "title-123")
        try item.moveTo(BedManagement.BatchedCleaningCycleStatus.resolved)
        #expect(item.status == BedManagement.BatchedCleaningCycleStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newBatchedCleaningCycle("code-335", title: "title-123")
        item.status = BedManagement.BatchedCleaningCycleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BatchedCleaningCycleStatus.`open`) }
    }
}
