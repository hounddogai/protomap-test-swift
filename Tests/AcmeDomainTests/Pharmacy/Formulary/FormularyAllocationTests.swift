@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyAllocationTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newFormularyAllocation("code-829", label: "label-390")
        #expect(item.status == Pharmacy.FormularyAllocationStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Pharmacy.newFormularyAllocation("code-829", label: "label-390")
        try item.moveTo(Pharmacy.FormularyAllocationStatus.reopened)
        #expect(item.status == Pharmacy.FormularyAllocationStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newFormularyAllocation("code-829", label: "label-390")
        item.status = Pharmacy.FormularyAllocationStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularyAllocationStatus.`open`) }
    }
}
