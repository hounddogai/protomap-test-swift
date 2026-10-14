@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientInventoryManifestTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newLenientInventoryManifest("code-323", title: "title-943")
        #expect(item.status == Pharmacy.LenientInventoryManifestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Pharmacy.newLenientInventoryManifest("code-323", title: "title-943")
        try item.moveTo(Pharmacy.LenientInventoryManifestStatus.validated)
        #expect(item.status == Pharmacy.LenientInventoryManifestStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newLenientInventoryManifest("code-323", title: "title-943")
        item.status = Pharmacy.LenientInventoryManifestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LenientInventoryManifestStatus.created) }
    }
}
