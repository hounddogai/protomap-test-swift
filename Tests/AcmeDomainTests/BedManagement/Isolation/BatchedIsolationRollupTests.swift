@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedIsolationRollupTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newBatchedIsolationRollup("code-530", title: "title-483")
        #expect(item.status == BedManagement.BatchedIsolationRollupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = BedManagement.newBatchedIsolationRollup("code-530", title: "title-483")
        try item.moveTo(BedManagement.BatchedIsolationRollupStatus.queued)
        #expect(item.status == BedManagement.BatchedIsolationRollupStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newBatchedIsolationRollup("code-530", title: "title-483")
        item.status = BedManagement.BatchedIsolationRollupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BatchedIsolationRollupStatus.new) }
    }
}
