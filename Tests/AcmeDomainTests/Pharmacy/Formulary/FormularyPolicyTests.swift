@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyPolicyTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newFormularyPolicy("code-976", label: "label-511")
        #expect(item.status == Pharmacy.FormularyPolicyStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newFormularyPolicy("code-976", label: "label-511")
        try item.moveTo(Pharmacy.FormularyPolicyStatus.approved)
        #expect(item.status == Pharmacy.FormularyPolicyStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newFormularyPolicy("code-976", label: "label-511")
        item.status = Pharmacy.FormularyPolicyStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularyPolicyStatus.proposed) }
    }
}
