@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionAuditTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newInteractionAudit("code-757", name: "name-897")
        #expect(item.status == Pharmacy.InteractionAuditStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Pharmacy.newInteractionAudit("code-757", name: "name-897")
        try item.moveTo(Pharmacy.InteractionAuditStatus.inProgress)
        #expect(item.status == Pharmacy.InteractionAuditStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newInteractionAudit("code-757", name: "name-897")
        item.status = Pharmacy.InteractionAuditStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionAuditStatus.planned) }
    }
}
