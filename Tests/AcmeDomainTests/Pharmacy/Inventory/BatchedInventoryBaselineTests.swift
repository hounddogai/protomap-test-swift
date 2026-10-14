@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedInventoryBaselineTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newBatchedInventoryBaseline("code-445", label: "label-89")
        #expect(item.status == Pharmacy.BatchedInventoryBaselineStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Pharmacy.newBatchedInventoryBaseline("code-445", label: "label-89")
        try item.moveTo(Pharmacy.BatchedInventoryBaselineStatus.validated)
        #expect(item.status == Pharmacy.BatchedInventoryBaselineStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newBatchedInventoryBaseline("code-445", label: "label-89")
        item.status = Pharmacy.BatchedInventoryBaselineStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.BatchedInventoryBaselineStatus.created) }
    }
}
