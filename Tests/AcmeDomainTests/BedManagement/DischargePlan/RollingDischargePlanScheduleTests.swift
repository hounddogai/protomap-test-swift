@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingDischargePlanScheduleTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newRollingDischargePlanSchedule("code-275", label: "label-597")
        #expect(item.status == BedManagement.RollingDischargePlanScheduleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = BedManagement.newRollingDischargePlanSchedule("code-275", label: "label-597")
        try item.moveTo(BedManagement.RollingDischargePlanScheduleStatus.cancelled)
        #expect(item.status == BedManagement.RollingDischargePlanScheduleStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newRollingDischargePlanSchedule("code-275", label: "label-597")
        item.status = BedManagement.RollingDischargePlanScheduleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.RollingDischargePlanScheduleStatus.planned) }
    }
}
