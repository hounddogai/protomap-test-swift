@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyAdjustmentTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newFormularyAdjustment("code-918", label: "label-591")
        #expect(item.status == Pharmacy.FormularyAdjustmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Pharmacy.newFormularyAdjustment("code-918", label: "label-591")
        try item.moveTo(Pharmacy.FormularyAdjustmentStatus.granted)
        #expect(item.status == Pharmacy.FormularyAdjustmentStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newFormularyAdjustment("code-918", label: "label-591")
        item.status = Pharmacy.FormularyAdjustmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularyAdjustmentStatus.requested) }
    }
}
