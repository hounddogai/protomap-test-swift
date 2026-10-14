@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalAccessionCheckpointTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newRegionalAccessionCheckpoint("code-79", name: "name-908")
        #expect(item.status == Labs.RegionalAccessionCheckpointStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Labs.newRegionalAccessionCheckpoint("code-79", name: "name-908")
        try item.moveTo(Labs.RegionalAccessionCheckpointStatus.scheduled)
        #expect(item.status == Labs.RegionalAccessionCheckpointStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newRegionalAccessionCheckpoint("code-79", name: "name-908")
        item.status = Labs.RegionalAccessionCheckpointStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RegionalAccessionCheckpointStatus.planned) }
    }
}
