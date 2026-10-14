@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialScheduleTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newCredentialSchedule("code-854", name: "name-716")
        #expect(item.status == Staffing.CredentialScheduleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newCredentialSchedule("code-854", name: "name-716")
        try item.moveTo(Staffing.CredentialScheduleStatus.approved)
        #expect(item.status == Staffing.CredentialScheduleStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newCredentialSchedule("code-854", name: "name-716")
        item.status = Staffing.CredentialScheduleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialScheduleStatus.proposed) }
    }
}
