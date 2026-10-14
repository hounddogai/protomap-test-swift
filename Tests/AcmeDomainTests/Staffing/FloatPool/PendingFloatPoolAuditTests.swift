@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingFloatPoolAuditTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newPendingFloatPoolAudit("code-967", label: "label-282")
        #expect(item.status == Staffing.PendingFloatPoolAuditStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Staffing.newPendingFloatPoolAudit("code-967", label: "label-282")
        try item.moveTo(Staffing.PendingFloatPoolAuditStatus.ready)
        #expect(item.status == Staffing.PendingFloatPoolAuditStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newPendingFloatPoolAudit("code-967", label: "label-282")
        item.status = Staffing.PendingFloatPoolAuditStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PendingFloatPoolAuditStatus.idle) }
    }
}
