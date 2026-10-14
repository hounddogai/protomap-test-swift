@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedCleaningOverrideTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newBatchedCleaningOverride("code-130", title: "title-668")
        #expect(item.status == BedManagement.BatchedCleaningOverrideStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = BedManagement.newBatchedCleaningOverride("code-130", title: "title-668")
        try item.moveTo(BedManagement.BatchedCleaningOverrideStatus.running)
        #expect(item.status == BedManagement.BatchedCleaningOverrideStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newBatchedCleaningOverride("code-130", title: "title-668")
        item.status = BedManagement.BatchedCleaningOverrideStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BatchedCleaningOverrideStatus.new) }
    }
}
