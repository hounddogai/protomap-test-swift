@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeAuditTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newOvertimeAudit("code-811", label: "label-603")
        #expect(item.status == Staffing.OvertimeAuditStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Staffing.newOvertimeAudit("code-811", label: "label-603")
        try item.moveTo(Staffing.OvertimeAuditStatus.suspended)
        #expect(item.status == Staffing.OvertimeAuditStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newOvertimeAudit("code-811", label: "label-603")
        item.status = Staffing.OvertimeAuditStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeAuditStatus.draft) }
    }
}
