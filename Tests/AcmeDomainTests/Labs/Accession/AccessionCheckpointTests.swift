@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionCheckpointTests {
    @Test func startsInRequested() throws {
        let item = Labs.newAccessionCheckpoint("code-915", label: "label-64")
        #expect(item.status == Labs.AccessionCheckpointStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Labs.newAccessionCheckpoint("code-915", label: "label-64")
        try item.moveTo(Labs.AccessionCheckpointStatus.granted)
        #expect(item.status == Labs.AccessionCheckpointStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newAccessionCheckpoint("code-915", label: "label-64")
        item.status = Labs.AccessionCheckpointStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionCheckpointStatus.requested) }
    }
}
