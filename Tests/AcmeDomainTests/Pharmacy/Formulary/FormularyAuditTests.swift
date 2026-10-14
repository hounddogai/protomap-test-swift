@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyAuditTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newFormularyAudit("code-490", label: "label-729")
        #expect(item.status == Pharmacy.FormularyAuditStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Pharmacy.newFormularyAudit("code-490", label: "label-729")
        try item.moveTo(Pharmacy.FormularyAuditStatus.granted)
        #expect(item.status == Pharmacy.FormularyAuditStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newFormularyAudit("code-490", label: "label-729")
        item.status = Pharmacy.FormularyAuditStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularyAuditStatus.requested) }
    }
}
