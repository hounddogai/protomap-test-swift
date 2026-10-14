@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryBaselineTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newInventoryBaseline("code-504", label: "label-969")
        #expect(item.status == Pharmacy.InventoryBaselineStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Pharmacy.newInventoryBaseline("code-504", label: "label-969")
        try item.moveTo(Pharmacy.InventoryBaselineStatus.resolved)
        #expect(item.status == Pharmacy.InventoryBaselineStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newInventoryBaseline("code-504", label: "label-969")
        item.status = Pharmacy.InventoryBaselineStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryBaselineStatus.`open`) }
    }
}
