@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedFormularySnapshotTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newCappedFormularySnapshot("code-799", name: "name-316")
        #expect(item.status == Pharmacy.CappedFormularySnapshotStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Pharmacy.newCappedFormularySnapshot("code-799", name: "name-316")
        try item.moveTo(Pharmacy.CappedFormularySnapshotStatus.active)
        #expect(item.status == Pharmacy.CappedFormularySnapshotStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newCappedFormularySnapshot("code-799", name: "name-316")
        item.status = Pharmacy.CappedFormularySnapshotStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.CappedFormularySnapshotStatus.draft) }
    }
}
