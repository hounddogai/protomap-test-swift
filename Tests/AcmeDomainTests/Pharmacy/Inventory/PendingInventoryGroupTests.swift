@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingInventoryGroupTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newPendingInventoryGroup("code-59", title: "title-764")
        #expect(item.status == Pharmacy.PendingInventoryGroupStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Pharmacy.newPendingInventoryGroup("code-59", title: "title-764")
        try item.moveTo(Pharmacy.PendingInventoryGroupStatus.rejected)
        #expect(item.status == Pharmacy.PendingInventoryGroupStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newPendingInventoryGroup("code-59", title: "title-764")
        item.status = Pharmacy.PendingInventoryGroupStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PendingInventoryGroupStatus.proposed) }
    }
}
