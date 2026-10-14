@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionCheckpointTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newInteractionCheckpoint("code-161", name: "name-710")
        #expect(item.status == Pharmacy.InteractionCheckpointStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Pharmacy.newInteractionCheckpoint("code-161", name: "name-710")
        try item.moveTo(Pharmacy.InteractionCheckpointStatus.running)
        #expect(item.status == Pharmacy.InteractionCheckpointStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newInteractionCheckpoint("code-161", name: "name-710")
        item.status = Pharmacy.InteractionCheckpointStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionCheckpointStatus.new) }
    }
}
