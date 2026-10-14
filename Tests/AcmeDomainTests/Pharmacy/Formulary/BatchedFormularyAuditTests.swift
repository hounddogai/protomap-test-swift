@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedFormularyAuditTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newBatchedFormularyAudit("code-25", label: "label-932")
        #expect(item.status == Pharmacy.BatchedFormularyAuditStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Pharmacy.newBatchedFormularyAudit("code-25", label: "label-932")
        try item.moveTo(Pharmacy.BatchedFormularyAuditStatus.running)
        #expect(item.status == Pharmacy.BatchedFormularyAuditStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newBatchedFormularyAudit("code-25", label: "label-932")
        item.status = Pharmacy.BatchedFormularyAuditStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.BatchedFormularyAuditStatus.new) }
    }
}
