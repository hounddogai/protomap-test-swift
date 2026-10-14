@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenCheckpointTests {
    @Test func startsInIdle() throws {
        let item = Labs.newSpecimenCheckpoint("code-800", label: "label-740")
        #expect(item.status == Labs.SpecimenCheckpointStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Labs.newSpecimenCheckpoint("code-800", label: "label-740")
        try item.moveTo(Labs.SpecimenCheckpointStatus.stopped)
        #expect(item.status == Labs.SpecimenCheckpointStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newSpecimenCheckpoint("code-800", label: "label-740")
        item.status = Labs.SpecimenCheckpointStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenCheckpointStatus.idle) }
    }
}
