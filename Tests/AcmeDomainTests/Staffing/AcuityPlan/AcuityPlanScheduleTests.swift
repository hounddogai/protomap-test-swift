@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanScheduleTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newAcuityPlanSchedule("code-246", label: "label-361")
        #expect(item.status == Staffing.AcuityPlanScheduleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Staffing.newAcuityPlanSchedule("code-246", label: "label-361")
        try item.moveTo(Staffing.AcuityPlanScheduleStatus.revoked)
        #expect(item.status == Staffing.AcuityPlanScheduleStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newAcuityPlanSchedule("code-246", label: "label-361")
        item.status = Staffing.AcuityPlanScheduleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanScheduleStatus.requested) }
    }
}
