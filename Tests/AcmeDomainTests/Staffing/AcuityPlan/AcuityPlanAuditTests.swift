@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanAuditTests {
    @Test func startsInNew() throws {
        let item = Staffing.newAcuityPlanAudit("code-956", title: "title-805")
        #expect(item.status == Staffing.AcuityPlanAuditStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Staffing.newAcuityPlanAudit("code-956", title: "title-805")
        try item.moveTo(Staffing.AcuityPlanAuditStatus.queued)
        #expect(item.status == Staffing.AcuityPlanAuditStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newAcuityPlanAudit("code-956", title: "title-805")
        item.status = Staffing.AcuityPlanAuditStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanAuditStatus.new) }
    }
}
