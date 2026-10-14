@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingRecallAuditTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newPendingRecallAudit("code-921", title: "title-650")
        #expect(item.status == Pharmacy.PendingRecallAuditStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Pharmacy.newPendingRecallAudit("code-921", title: "title-650")
        try item.moveTo(Pharmacy.PendingRecallAuditStatus.scheduled)
        #expect(item.status == Pharmacy.PendingRecallAuditStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newPendingRecallAudit("code-921", title: "title-650")
        item.status = Pharmacy.PendingRecallAuditStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PendingRecallAuditStatus.planned) }
    }
}
