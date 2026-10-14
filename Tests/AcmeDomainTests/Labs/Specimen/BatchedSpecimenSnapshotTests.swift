@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedSpecimenSnapshotTests {
    @Test func startsInProposed() throws {
        let item = Labs.newBatchedSpecimenSnapshot("code-528", name: "name-954")
        #expect(item.status == Labs.BatchedSpecimenSnapshotStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newBatchedSpecimenSnapshot("code-528", name: "name-954")
        try item.moveTo(Labs.BatchedSpecimenSnapshotStatus.approved)
        #expect(item.status == Labs.BatchedSpecimenSnapshotStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newBatchedSpecimenSnapshot("code-528", name: "name-954")
        item.status = Labs.BatchedSpecimenSnapshotStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.BatchedSpecimenSnapshotStatus.proposed) }
    }
}
