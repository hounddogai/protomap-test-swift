@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedInventoryRequestTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newCappedInventoryRequest("code-408", label: "label-965")
        #expect(item.status == Pharmacy.CappedInventoryRequestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Pharmacy.newCappedInventoryRequest("code-408", label: "label-965")
        try item.moveTo(Pharmacy.CappedInventoryRequestStatus.inProgress)
        #expect(item.status == Pharmacy.CappedInventoryRequestStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newCappedInventoryRequest("code-408", label: "label-965")
        item.status = Pharmacy.CappedInventoryRequestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.CappedInventoryRequestStatus.planned) }
    }
}
