@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimePreferenceTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newOvertimePreference("code-719", title: "title-69")
        #expect(item.status == Staffing.OvertimePreferenceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newOvertimePreference("code-719", title: "title-69")
        try item.moveTo(Staffing.OvertimePreferenceStatus.approved)
        #expect(item.status == Staffing.OvertimePreferenceStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newOvertimePreference("code-719", title: "title-69")
        item.status = Staffing.OvertimePreferenceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimePreferenceStatus.proposed) }
    }
}
