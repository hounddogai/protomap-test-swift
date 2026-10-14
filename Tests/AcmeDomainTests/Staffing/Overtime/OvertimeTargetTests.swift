@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeTargetTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newOvertimeTarget("code-545", label: "label-102")
        #expect(item.status == Staffing.OvertimeTargetStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Staffing.newOvertimeTarget("code-545", label: "label-102")
        try item.moveTo(Staffing.OvertimeTargetStatus.suspended)
        #expect(item.status == Staffing.OvertimeTargetStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newOvertimeTarget("code-545", label: "label-102")
        item.status = Staffing.OvertimeTargetStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeTargetStatus.draft) }
    }
}
