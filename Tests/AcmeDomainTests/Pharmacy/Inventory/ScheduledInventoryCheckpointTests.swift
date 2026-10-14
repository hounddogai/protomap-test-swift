@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledInventoryCheckpointTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newScheduledInventoryCheckpoint("code-346", label: "label-197")
        #expect(item.status == Pharmacy.ScheduledInventoryCheckpointStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Pharmacy.newScheduledInventoryCheckpoint("code-346", label: "label-197")
        try item.moveTo(Pharmacy.ScheduledInventoryCheckpointStatus.revoked)
        #expect(item.status == Pharmacy.ScheduledInventoryCheckpointStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newScheduledInventoryCheckpoint("code-346", label: "label-197")
        item.status = Pharmacy.ScheduledInventoryCheckpointStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.ScheduledInventoryCheckpointStatus.requested) }
    }
}
