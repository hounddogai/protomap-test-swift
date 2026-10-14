@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingAccessionCheckpointTests {
    @Test func startsInDraft() throws {
        let item = Labs.newRollingAccessionCheckpoint("code-1", title: "title-861")
        #expect(item.status == Labs.RollingAccessionCheckpointStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Labs.newRollingAccessionCheckpoint("code-1", title: "title-861")
        try item.moveTo(Labs.RollingAccessionCheckpointStatus.closed)
        #expect(item.status == Labs.RollingAccessionCheckpointStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newRollingAccessionCheckpoint("code-1", title: "title-861")
        item.status = Labs.RollingAccessionCheckpointStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RollingAccessionCheckpointStatus.draft) }
    }
}
