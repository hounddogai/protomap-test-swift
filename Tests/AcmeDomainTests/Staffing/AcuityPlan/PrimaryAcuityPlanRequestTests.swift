@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryAcuityPlanRequestTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newPrimaryAcuityPlanRequest("code-136", name: "name-400")
        #expect(item.status == Staffing.PrimaryAcuityPlanRequestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Staffing.newPrimaryAcuityPlanRequest("code-136", name: "name-400")
        try item.moveTo(Staffing.PrimaryAcuityPlanRequestStatus.stopped)
        #expect(item.status == Staffing.PrimaryAcuityPlanRequestStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newPrimaryAcuityPlanRequest("code-136", name: "name-400")
        item.status = Staffing.PrimaryAcuityPlanRequestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PrimaryAcuityPlanRequestStatus.idle) }
    }
}
