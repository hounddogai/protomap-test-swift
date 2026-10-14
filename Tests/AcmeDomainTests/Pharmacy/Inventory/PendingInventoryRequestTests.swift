@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingInventoryRequestTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newPendingInventoryRequest("code-915", title: "title-17")
        #expect(item.status == Pharmacy.PendingInventoryRequestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Pharmacy.newPendingInventoryRequest("code-915", title: "title-17")
        try item.moveTo(Pharmacy.PendingInventoryRequestStatus.validated)
        #expect(item.status == Pharmacy.PendingInventoryRequestStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newPendingInventoryRequest("code-915", title: "title-17")
        item.status = Pharmacy.PendingInventoryRequestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PendingInventoryRequestStatus.created) }
    }
}
