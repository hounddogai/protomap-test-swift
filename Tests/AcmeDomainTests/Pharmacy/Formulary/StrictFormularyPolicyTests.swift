@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictFormularyPolicyTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newStrictFormularyPolicy("code-111", label: "label-820")
        #expect(item.status == Pharmacy.StrictFormularyPolicyStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Pharmacy.newStrictFormularyPolicy("code-111", label: "label-820")
        try item.moveTo(Pharmacy.StrictFormularyPolicyStatus.withdrawn)
        #expect(item.status == Pharmacy.StrictFormularyPolicyStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newStrictFormularyPolicy("code-111", label: "label-820")
        item.status = Pharmacy.StrictFormularyPolicyStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.StrictFormularyPolicyStatus.proposed) }
    }
}
