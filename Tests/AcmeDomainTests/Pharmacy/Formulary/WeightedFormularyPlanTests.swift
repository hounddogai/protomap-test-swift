@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedFormularyPlanTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newWeightedFormularyPlan("code-664", label: "label-521")
        #expect(item.status == Pharmacy.WeightedFormularyPlanStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Pharmacy.newWeightedFormularyPlan("code-664", label: "label-521")
        try item.moveTo(Pharmacy.WeightedFormularyPlanStatus.running)
        #expect(item.status == Pharmacy.WeightedFormularyPlanStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newWeightedFormularyPlan("code-664", label: "label-521")
        item.status = Pharmacy.WeightedFormularyPlanStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.WeightedFormularyPlanStatus.new) }
    }
}
