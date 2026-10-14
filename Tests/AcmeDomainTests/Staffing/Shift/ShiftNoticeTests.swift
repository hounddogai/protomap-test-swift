@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftNoticeTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newShiftNotice("code-15", label: "label-262")
        #expect(item.status == Staffing.ShiftNoticeStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Staffing.newShiftNotice("code-15", label: "label-262")
        try item.moveTo(Staffing.ShiftNoticeStatus.warming)
        #expect(item.status == Staffing.ShiftNoticeStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newShiftNotice("code-15", label: "label-262")
        item.status = Staffing.ShiftNoticeStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftNoticeStatus.idle) }
    }
}
