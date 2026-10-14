@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyAssignmentTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newFormularyAssignment("code-611", name: "name-381")
        #expect(item.status == Pharmacy.FormularyAssignmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newFormularyAssignment("code-611", name: "name-381")
        try item.moveTo(Pharmacy.FormularyAssignmentStatus.approved)
        #expect(item.status == Pharmacy.FormularyAssignmentStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newFormularyAssignment("code-611", name: "name-381")
        item.status = Pharmacy.FormularyAssignmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularyAssignmentStatus.proposed) }
    }
}
