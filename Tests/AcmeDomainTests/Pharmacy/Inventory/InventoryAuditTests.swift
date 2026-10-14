@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryAuditTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newInventoryAudit("code-36", label: "label-901")
        #expect(item.status == Pharmacy.InventoryAuditStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Pharmacy.newInventoryAudit("code-36", label: "label-901")
        try item.moveTo(Pharmacy.InventoryAuditStatus.revoked)
        #expect(item.status == Pharmacy.InventoryAuditStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newInventoryAudit("code-36", label: "label-901")
        item.status = Pharmacy.InventoryAuditStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryAuditStatus.requested) }
    }
}
