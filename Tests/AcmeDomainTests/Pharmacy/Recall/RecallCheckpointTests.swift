@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallCheckpointTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newRecallCheckpoint("code-164", title: "title-998")
        #expect(item.status == Pharmacy.RecallCheckpointStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Pharmacy.newRecallCheckpoint("code-164", title: "title-998")
        try item.moveTo(Pharmacy.RecallCheckpointStatus.validated)
        #expect(item.status == Pharmacy.RecallCheckpointStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newRecallCheckpoint("code-164", title: "title-998")
        item.status = Pharmacy.RecallCheckpointStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallCheckpointStatus.created) }
    }
}
