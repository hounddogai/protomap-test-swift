@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyRecordTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newFormularyRecord("code-89", name: "name-579")
        #expect(item.status == Pharmacy.FormularyRecordStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Pharmacy.newFormularyRecord("code-89", name: "name-579")
        try item.moveTo(Pharmacy.FormularyRecordStatus.rejected)
        #expect(item.status == Pharmacy.FormularyRecordStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newFormularyRecord("code-89", name: "name-579")
        item.status = Pharmacy.FormularyRecordStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularyRecordStatus.proposed) }
    }
}
