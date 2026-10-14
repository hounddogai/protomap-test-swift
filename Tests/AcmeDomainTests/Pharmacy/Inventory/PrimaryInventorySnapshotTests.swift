@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryInventorySnapshotTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newPrimaryInventorySnapshot("code-273", label: "label-670")
        #expect(item.status == Pharmacy.PrimaryInventorySnapshotStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Pharmacy.newPrimaryInventorySnapshot("code-273", label: "label-670")
        try item.moveTo(Pharmacy.PrimaryInventorySnapshotStatus.resolved)
        #expect(item.status == Pharmacy.PrimaryInventorySnapshotStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newPrimaryInventorySnapshot("code-273", label: "label-670")
        item.status = Pharmacy.PrimaryInventorySnapshotStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PrimaryInventorySnapshotStatus.`open`) }
    }
}
