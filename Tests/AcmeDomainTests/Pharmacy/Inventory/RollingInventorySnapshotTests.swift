@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingInventorySnapshotTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newRollingInventorySnapshot("code-146", title: "title-297")
        #expect(item.status == Pharmacy.RollingInventorySnapshotStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Pharmacy.newRollingInventorySnapshot("code-146", title: "title-297")
        try item.moveTo(Pharmacy.RollingInventorySnapshotStatus.completed)
        #expect(item.status == Pharmacy.RollingInventorySnapshotStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newRollingInventorySnapshot("code-146", title: "title-297")
        item.status = Pharmacy.RollingInventorySnapshotStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RollingInventorySnapshotStatus.planned) }
    }
}
