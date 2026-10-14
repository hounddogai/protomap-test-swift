@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanGroupTests {
    @Test func startsInNew() throws {
        let item = Staffing.newAcuityPlanGroup("code-877", label: "label-164")
        #expect(item.status == Staffing.AcuityPlanGroupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Staffing.newAcuityPlanGroup("code-877", label: "label-164")
        try item.moveTo(Staffing.AcuityPlanGroupStatus.queued)
        #expect(item.status == Staffing.AcuityPlanGroupStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newAcuityPlanGroup("code-877", label: "label-164")
        item.status = Staffing.AcuityPlanGroupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanGroupStatus.new) }
    }
}
