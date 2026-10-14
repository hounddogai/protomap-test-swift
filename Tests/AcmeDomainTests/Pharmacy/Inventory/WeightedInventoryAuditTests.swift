@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedInventoryAuditTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newWeightedInventoryAudit("code-261", name: "name-338")
        #expect(item.status == Pharmacy.WeightedInventoryAuditStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Pharmacy.newWeightedInventoryAudit("code-261", name: "name-338")
        try item.moveTo(Pharmacy.WeightedInventoryAuditStatus.revoked)
        #expect(item.status == Pharmacy.WeightedInventoryAuditStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newWeightedInventoryAudit("code-261", name: "name-338")
        item.status = Pharmacy.WeightedInventoryAuditStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.WeightedInventoryAuditStatus.requested) }
    }
}
