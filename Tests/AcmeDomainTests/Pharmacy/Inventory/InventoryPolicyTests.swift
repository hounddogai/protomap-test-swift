@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryPolicyTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newInventoryPolicy("code-70", name: "name-626")
        #expect(item.status == Pharmacy.InventoryPolicyStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Pharmacy.newInventoryPolicy("code-70", name: "name-626")
        try item.moveTo(Pharmacy.InventoryPolicyStatus.inProgress)
        #expect(item.status == Pharmacy.InventoryPolicyStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newInventoryPolicy("code-70", name: "name-626")
        item.status = Pharmacy.InventoryPolicyStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryPolicyStatus.planned) }
    }
}
