@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryDigestTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newInventoryDigest("code-871", title: "title-316")
        #expect(item.status == Pharmacy.InventoryDigestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Pharmacy.newInventoryDigest("code-871", title: "title-316")
        try item.moveTo(Pharmacy.InventoryDigestStatus.running)
        #expect(item.status == Pharmacy.InventoryDigestStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newInventoryDigest("code-871", title: "title-316")
        item.status = Pharmacy.InventoryDigestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryDigestStatus.new) }
    }
}
