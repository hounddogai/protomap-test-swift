@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyPlanTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newFormularyPlan("code-957", label: "label-406")
        #expect(item.status == Pharmacy.FormularyPlanStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Pharmacy.newFormularyPlan("code-957", label: "label-406")
        try item.moveTo(Pharmacy.FormularyPlanStatus.retired)
        #expect(item.status == Pharmacy.FormularyPlanStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newFormularyPlan("code-957", label: "label-406")
        item.status = Pharmacy.FormularyPlanStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularyPlanStatus.created) }
    }
}
