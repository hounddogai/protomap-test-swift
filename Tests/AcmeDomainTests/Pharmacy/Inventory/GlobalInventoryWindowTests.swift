@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalInventoryWindowTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newGlobalInventoryWindow("code-64", label: "label-764")
        #expect(item.status == Pharmacy.GlobalInventoryWindowStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Pharmacy.newGlobalInventoryWindow("code-64", label: "label-764")
        try item.moveTo(Pharmacy.GlobalInventoryWindowStatus.validated)
        #expect(item.status == Pharmacy.GlobalInventoryWindowStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newGlobalInventoryWindow("code-64", label: "label-764")
        item.status = Pharmacy.GlobalInventoryWindowStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.GlobalInventoryWindowStatus.created) }
    }
}
