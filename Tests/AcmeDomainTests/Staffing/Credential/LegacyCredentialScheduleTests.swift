@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyCredentialScheduleTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newLegacyCredentialSchedule("code-392", label: "label-350")
        #expect(item.status == Staffing.LegacyCredentialScheduleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Staffing.newLegacyCredentialSchedule("code-392", label: "label-350")
        try item.moveTo(Staffing.LegacyCredentialScheduleStatus.draining)
        #expect(item.status == Staffing.LegacyCredentialScheduleStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newLegacyCredentialSchedule("code-392", label: "label-350")
        item.status = Staffing.LegacyCredentialScheduleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LegacyCredentialScheduleStatus.idle) }
    }
}
