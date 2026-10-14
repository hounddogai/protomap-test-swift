@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedAccessionCheckpointTests {
    @Test func startsInOpen() throws {
        let item = Labs.newCappedAccessionCheckpoint("code-696", name: "name-199")
        #expect(item.status == Labs.CappedAccessionCheckpointStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Labs.newCappedAccessionCheckpoint("code-696", name: "name-199")
        try item.moveTo(Labs.CappedAccessionCheckpointStatus.resolved)
        #expect(item.status == Labs.CappedAccessionCheckpointStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newCappedAccessionCheckpoint("code-696", name: "name-199")
        item.status = Labs.CappedAccessionCheckpointStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CappedAccessionCheckpointStatus.`open`) }
    }
}
