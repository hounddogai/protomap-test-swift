@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledFloatPoolAuditTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newScheduledFloatPoolAudit("code-898", label: "label-291")
        #expect(item.status == Staffing.ScheduledFloatPoolAuditStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newScheduledFloatPoolAudit("code-898", label: "label-291")
        try item.moveTo(Staffing.ScheduledFloatPoolAuditStatus.granted)
        #expect(item.status == Staffing.ScheduledFloatPoolAuditStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newScheduledFloatPoolAudit("code-898", label: "label-291")
        item.status = Staffing.ScheduledFloatPoolAuditStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ScheduledFloatPoolAuditStatus.requested) }
    }
}
