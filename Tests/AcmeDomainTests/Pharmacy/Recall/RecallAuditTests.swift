@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallAuditTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newRecallAudit("code-406", label: "label-625")
        #expect(item.status == Pharmacy.RecallAuditStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Pharmacy.newRecallAudit("code-406", label: "label-625")
        try item.moveTo(Pharmacy.RecallAuditStatus.rejected)
        #expect(item.status == Pharmacy.RecallAuditStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newRecallAudit("code-406", label: "label-625")
        item.status = Pharmacy.RecallAuditStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallAuditStatus.proposed) }
    }
}
