@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledInventorySnapshotTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newScheduledInventorySnapshot("code-331", title: "title-204")
        #expect(item.status == Pharmacy.ScheduledInventorySnapshotStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Pharmacy.newScheduledInventorySnapshot("code-331", title: "title-204")
        try item.moveTo(Pharmacy.ScheduledInventorySnapshotStatus.expired)
        #expect(item.status == Pharmacy.ScheduledInventorySnapshotStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newScheduledInventorySnapshot("code-331", title: "title-204")
        item.status = Pharmacy.ScheduledInventorySnapshotStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.ScheduledInventorySnapshotStatus.requested) }
    }
}
