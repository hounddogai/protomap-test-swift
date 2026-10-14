@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedRecallSnapshotTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newCappedRecallSnapshot("code-732", name: "name-719")
        #expect(item.status == Pharmacy.CappedRecallSnapshotStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Pharmacy.newCappedRecallSnapshot("code-732", name: "name-719")
        try item.moveTo(Pharmacy.CappedRecallSnapshotStatus.draining)
        #expect(item.status == Pharmacy.CappedRecallSnapshotStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newCappedRecallSnapshot("code-732", name: "name-719")
        item.status = Pharmacy.CappedRecallSnapshotStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.CappedRecallSnapshotStatus.idle) }
    }
}
