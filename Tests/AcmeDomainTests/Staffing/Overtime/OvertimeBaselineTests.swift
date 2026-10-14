@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeBaselineTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newOvertimeBaseline("code-978", title: "title-41")
        #expect(item.status == Staffing.OvertimeBaselineStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newOvertimeBaseline("code-978", title: "title-41")
        try item.moveTo(Staffing.OvertimeBaselineStatus.granted)
        #expect(item.status == Staffing.OvertimeBaselineStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newOvertimeBaseline("code-978", title: "title-41")
        item.status = Staffing.OvertimeBaselineStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeBaselineStatus.requested) }
    }
}
