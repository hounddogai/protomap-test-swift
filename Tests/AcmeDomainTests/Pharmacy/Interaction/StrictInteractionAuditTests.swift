@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictInteractionAuditTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newStrictInteractionAudit("code-821", label: "label-99")
        #expect(item.status == Pharmacy.StrictInteractionAuditStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newStrictInteractionAudit("code-821", label: "label-99")
        try item.moveTo(Pharmacy.StrictInteractionAuditStatus.approved)
        #expect(item.status == Pharmacy.StrictInteractionAuditStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newStrictInteractionAudit("code-821", label: "label-99")
        item.status = Pharmacy.StrictInteractionAuditStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.StrictInteractionAuditStatus.proposed) }
    }
}
