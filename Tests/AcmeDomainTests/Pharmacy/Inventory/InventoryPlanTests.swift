@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryPlanTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newInventoryPlan("code-269", title: "title-247")
        #expect(item.status == Pharmacy.InventoryPlanStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Pharmacy.newInventoryPlan("code-269", title: "title-247")
        try item.moveTo(Pharmacy.InventoryPlanStatus.inProgress)
        #expect(item.status == Pharmacy.InventoryPlanStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newInventoryPlan("code-269", title: "title-247")
        item.status = Pharmacy.InventoryPlanStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryPlanStatus.planned) }
    }
}
