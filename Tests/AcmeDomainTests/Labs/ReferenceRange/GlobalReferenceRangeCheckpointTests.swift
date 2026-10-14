@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalReferenceRangeCheckpointTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newGlobalReferenceRangeCheckpoint("code-635", name: "name-669")
        #expect(item.status == Labs.GlobalReferenceRangeCheckpointStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Labs.newGlobalReferenceRangeCheckpoint("code-635", name: "name-669")
        try item.moveTo(Labs.GlobalReferenceRangeCheckpointStatus.scheduled)
        #expect(item.status == Labs.GlobalReferenceRangeCheckpointStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newGlobalReferenceRangeCheckpoint("code-635", name: "name-669")
        item.status = Labs.GlobalReferenceRangeCheckpointStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.GlobalReferenceRangeCheckpointStatus.planned) }
    }
}
