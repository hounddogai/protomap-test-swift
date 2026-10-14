@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryInventoryPlanTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newPrimaryInventoryPlan("code-835", title: "title-659")
        #expect(item.status == Pharmacy.PrimaryInventoryPlanStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newPrimaryInventoryPlan("code-835", title: "title-659")
        try item.moveTo(Pharmacy.PrimaryInventoryPlanStatus.approved)
        #expect(item.status == Pharmacy.PrimaryInventoryPlanStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newPrimaryInventoryPlan("code-835", title: "title-659")
        item.status = Pharmacy.PrimaryInventoryPlanStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PrimaryInventoryPlanStatus.proposed) }
    }
}
