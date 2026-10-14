@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeCheckpointTests {
    @Test func startsInNew() throws {
        let item = Labs.newReferenceRangeCheckpoint("code-483", name: "name-419")
        #expect(item.status == Labs.ReferenceRangeCheckpointStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Labs.newReferenceRangeCheckpoint("code-483", name: "name-419")
        try item.moveTo(Labs.ReferenceRangeCheckpointStatus.running)
        #expect(item.status == Labs.ReferenceRangeCheckpointStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newReferenceRangeCheckpoint("code-483", name: "name-419")
        item.status = Labs.ReferenceRangeCheckpointStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeCheckpointStatus.new) }
    }
}
