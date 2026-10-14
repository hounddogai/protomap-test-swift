@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackAcuityPlanRequestTests {
    @Test func startsInNew() throws {
        let item = Staffing.newFallbackAcuityPlanRequest("code-899", name: "name-709")
        #expect(item.status == Staffing.FallbackAcuityPlanRequestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Staffing.newFallbackAcuityPlanRequest("code-899", name: "name-709")
        try item.moveTo(Staffing.FallbackAcuityPlanRequestStatus.queued)
        #expect(item.status == Staffing.FallbackAcuityPlanRequestStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newFallbackAcuityPlanRequest("code-899", name: "name-709")
        item.status = Staffing.FallbackAcuityPlanRequestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FallbackAcuityPlanRequestStatus.new) }
    }
}
