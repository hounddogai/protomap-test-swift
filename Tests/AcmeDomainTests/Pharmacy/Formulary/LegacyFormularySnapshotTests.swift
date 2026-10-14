@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyFormularySnapshotTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newLegacyFormularySnapshot("code-207", title: "title-928")
        #expect(item.status == Pharmacy.LegacyFormularySnapshotStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Pharmacy.newLegacyFormularySnapshot("code-207", title: "title-928")
        try item.moveTo(Pharmacy.LegacyFormularySnapshotStatus.warming)
        #expect(item.status == Pharmacy.LegacyFormularySnapshotStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newLegacyFormularySnapshot("code-207", title: "title-928")
        item.status = Pharmacy.LegacyFormularySnapshotStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LegacyFormularySnapshotStatus.idle) }
    }
}
