@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualInventorySnapshotTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newManualInventorySnapshot("code-575", label: "label-908")
        #expect(item.status == Pharmacy.ManualInventorySnapshotStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Pharmacy.newManualInventorySnapshot("code-575", label: "label-908")
        try item.moveTo(Pharmacy.ManualInventorySnapshotStatus.inReview)
        #expect(item.status == Pharmacy.ManualInventorySnapshotStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newManualInventorySnapshot("code-575", label: "label-908")
        item.status = Pharmacy.ManualInventorySnapshotStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.ManualInventorySnapshotStatus.`open`) }
    }
}
