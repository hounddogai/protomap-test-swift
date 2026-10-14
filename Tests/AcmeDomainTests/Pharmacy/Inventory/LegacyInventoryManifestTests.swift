@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyInventoryManifestTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newLegacyInventoryManifest("code-860", label: "label-118")
        #expect(item.status == Pharmacy.LegacyInventoryManifestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Pharmacy.newLegacyInventoryManifest("code-860", label: "label-118")
        try item.moveTo(Pharmacy.LegacyInventoryManifestStatus.running)
        #expect(item.status == Pharmacy.LegacyInventoryManifestStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newLegacyInventoryManifest("code-860", label: "label-118")
        item.status = Pharmacy.LegacyInventoryManifestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LegacyInventoryManifestStatus.new) }
    }
}
