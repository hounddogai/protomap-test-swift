@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedSpecimenPolicyTests {
    @Test func startsInRequested() throws {
        let item = Labs.newBatchedSpecimenPolicy("code-337", name: "name-224")
        #expect(item.status == Labs.BatchedSpecimenPolicyStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Labs.newBatchedSpecimenPolicy("code-337", name: "name-224")
        try item.moveTo(Labs.BatchedSpecimenPolicyStatus.granted)
        #expect(item.status == Labs.BatchedSpecimenPolicyStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newBatchedSpecimenPolicy("code-337", name: "name-224")
        item.status = Labs.BatchedSpecimenPolicyStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.BatchedSpecimenPolicyStatus.requested) }
    }
}
