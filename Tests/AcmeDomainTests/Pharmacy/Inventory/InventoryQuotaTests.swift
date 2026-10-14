@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryQuotaTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newInventoryQuota("code-562", name: "name-922")
        #expect(item.status == Pharmacy.InventoryQuotaStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Pharmacy.newInventoryQuota("code-562", name: "name-922")
        try item.moveTo(Pharmacy.InventoryQuotaStatus.queued)
        #expect(item.status == Pharmacy.InventoryQuotaStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newInventoryQuota("code-562", name: "name-922")
        item.status = Pharmacy.InventoryQuotaStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryQuotaStatus.new) }
    }
}
