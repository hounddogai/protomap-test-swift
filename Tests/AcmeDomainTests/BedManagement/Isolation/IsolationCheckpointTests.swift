@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationCheckpointTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newIsolationCheckpoint("code-922", label: "label-826")
        #expect(item.status == BedManagement.IsolationCheckpointStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = BedManagement.newIsolationCheckpoint("code-922", label: "label-826")
        try item.moveTo(BedManagement.IsolationCheckpointStatus.resolved)
        #expect(item.status == BedManagement.IsolationCheckpointStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newIsolationCheckpoint("code-922", label: "label-826")
        item.status = BedManagement.IsolationCheckpointStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationCheckpointStatus.`open`) }
    }
}
