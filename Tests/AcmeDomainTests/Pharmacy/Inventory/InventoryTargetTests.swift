@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryTargetTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newInventoryTarget("code-762", name: "name-344")
        #expect(item.status == Pharmacy.InventoryTargetStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Pharmacy.newInventoryTarget("code-762", name: "name-344")
        try item.moveTo(Pharmacy.InventoryTargetStatus.revoked)
        #expect(item.status == Pharmacy.InventoryTargetStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newInventoryTarget("code-762", name: "name-344")
        item.status = Pharmacy.InventoryTargetStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryTargetStatus.requested) }
    }
}
