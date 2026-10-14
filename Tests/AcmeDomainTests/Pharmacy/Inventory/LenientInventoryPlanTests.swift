@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientInventoryPlanTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newLenientInventoryPlan("code-742", label: "label-309")
        #expect(item.status == Pharmacy.LenientInventoryPlanStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Pharmacy.newLenientInventoryPlan("code-742", label: "label-309")
        try item.moveTo(Pharmacy.LenientInventoryPlanStatus.retired)
        #expect(item.status == Pharmacy.LenientInventoryPlanStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newLenientInventoryPlan("code-742", label: "label-309")
        item.status = Pharmacy.LenientInventoryPlanStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LenientInventoryPlanStatus.created) }
    }
}
