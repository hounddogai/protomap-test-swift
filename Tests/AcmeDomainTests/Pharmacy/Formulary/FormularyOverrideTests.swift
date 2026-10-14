@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyOverrideTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newFormularyOverride("code-203", label: "label-53")
        #expect(item.status == Pharmacy.FormularyOverrideStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newFormularyOverride("code-203", label: "label-53")
        try item.moveTo(Pharmacy.FormularyOverrideStatus.approved)
        #expect(item.status == Pharmacy.FormularyOverrideStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newFormularyOverride("code-203", label: "label-53")
        item.status = Pharmacy.FormularyOverrideStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularyOverrideStatus.proposed) }
    }
}
