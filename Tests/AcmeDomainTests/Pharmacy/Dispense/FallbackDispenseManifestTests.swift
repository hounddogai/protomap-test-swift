@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackDispenseManifestTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newFallbackDispenseManifest("code-969", name: "name-876")
        #expect(item.status == Pharmacy.FallbackDispenseManifestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Pharmacy.newFallbackDispenseManifest("code-969", name: "name-876")
        try item.moveTo(Pharmacy.FallbackDispenseManifestStatus.draining)
        #expect(item.status == Pharmacy.FallbackDispenseManifestStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newFallbackDispenseManifest("code-969", name: "name-876")
        item.status = Pharmacy.FallbackDispenseManifestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FallbackDispenseManifestStatus.idle) }
    }
}
