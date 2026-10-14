@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualInventoryManifestTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newManualInventoryManifest("code-99", label: "label-824")
        #expect(item.status == Pharmacy.ManualInventoryManifestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newManualInventoryManifest("code-99", label: "label-824")
        try item.moveTo(Pharmacy.ManualInventoryManifestStatus.approved)
        #expect(item.status == Pharmacy.ManualInventoryManifestStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newManualInventoryManifest("code-99", label: "label-824")
        item.status = Pharmacy.ManualInventoryManifestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.ManualInventoryManifestStatus.proposed) }
    }
}
