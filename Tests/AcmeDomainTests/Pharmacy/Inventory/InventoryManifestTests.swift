@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryManifestTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newInventoryManifest("code-453", title: "title-430")
        #expect(item.status == Pharmacy.InventoryManifestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Pharmacy.newInventoryManifest("code-453", title: "title-430")
        try item.moveTo(Pharmacy.InventoryManifestStatus.expired)
        #expect(item.status == Pharmacy.InventoryManifestStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newInventoryManifest("code-453", title: "title-430")
        item.status = Pharmacy.InventoryManifestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryManifestStatus.requested) }
    }
}
