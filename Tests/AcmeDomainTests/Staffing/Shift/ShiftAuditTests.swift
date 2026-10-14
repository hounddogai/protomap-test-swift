@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftAuditTests {
    @Test func startsInNew() throws {
        let item = Staffing.newShiftAudit("code-717", title: "title-723")
        #expect(item.status == Staffing.ShiftAuditStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Staffing.newShiftAudit("code-717", title: "title-723")
        try item.moveTo(Staffing.ShiftAuditStatus.running)
        #expect(item.status == Staffing.ShiftAuditStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newShiftAudit("code-717", title: "title-723")
        item.status = Staffing.ShiftAuditStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftAuditStatus.new) }
    }
}
