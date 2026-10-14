@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryExceptionTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newInventoryException("code-120", label: "label-572")
        #expect(item.status == Pharmacy.InventoryExceptionStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Pharmacy.newInventoryException("code-120", label: "label-572")
        try item.moveTo(Pharmacy.InventoryExceptionStatus.reopened)
        #expect(item.status == Pharmacy.InventoryExceptionStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newInventoryException("code-120", label: "label-572")
        item.status = Pharmacy.InventoryExceptionStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryExceptionStatus.`open`) }
    }
}
