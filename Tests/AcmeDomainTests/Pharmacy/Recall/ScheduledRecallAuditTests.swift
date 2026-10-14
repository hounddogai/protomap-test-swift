@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledRecallAuditTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newScheduledRecallAudit("code-839", label: "label-626")
        #expect(item.status == Pharmacy.ScheduledRecallAuditStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Pharmacy.newScheduledRecallAudit("code-839", label: "label-626")
        try item.moveTo(Pharmacy.ScheduledRecallAuditStatus.stopped)
        #expect(item.status == Pharmacy.ScheduledRecallAuditStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newScheduledRecallAudit("code-839", label: "label-626")
        item.status = Pharmacy.ScheduledRecallAuditStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.ScheduledRecallAuditStatus.idle) }
    }
}
