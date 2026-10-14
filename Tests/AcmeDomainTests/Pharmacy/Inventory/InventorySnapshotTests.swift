@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventorySnapshotTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newInventorySnapshot("code-311", label: "label-155")
        #expect(item.status == Pharmacy.InventorySnapshotStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Pharmacy.newInventorySnapshot("code-311", label: "label-155")
        try item.moveTo(Pharmacy.InventorySnapshotStatus.warming)
        #expect(item.status == Pharmacy.InventorySnapshotStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newInventorySnapshot("code-311", label: "label-155")
        item.status = Pharmacy.InventorySnapshotStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventorySnapshotStatus.idle) }
    }
}
