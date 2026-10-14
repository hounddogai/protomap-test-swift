@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeRuleTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newOvertimeRule("code-709", label: "label-433")
        #expect(item.status == Staffing.OvertimeRuleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newOvertimeRule("code-709", label: "label-433")
        try item.moveTo(Staffing.OvertimeRuleStatus.granted)
        #expect(item.status == Staffing.OvertimeRuleStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newOvertimeRule("code-709", label: "label-433")
        item.status = Staffing.OvertimeRuleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeRuleStatus.requested) }
    }
}
