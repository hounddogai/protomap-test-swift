@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryMilestoneTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newInventoryMilestone("code-175", name: "name-899")
        #expect(item.status == Pharmacy.InventoryMilestoneStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Pharmacy.newInventoryMilestone("code-175", name: "name-899")
        try item.moveTo(Pharmacy.InventoryMilestoneStatus.scheduled)
        #expect(item.status == Pharmacy.InventoryMilestoneStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newInventoryMilestone("code-175", name: "name-899")
        item.status = Pharmacy.InventoryMilestoneStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryMilestoneStatus.planned) }
    }
}
