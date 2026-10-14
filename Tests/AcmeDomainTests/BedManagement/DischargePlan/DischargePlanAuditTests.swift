@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanAuditTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newDischargePlanAudit("code-538", title: "title-357")
        #expect(item.status == BedManagement.DischargePlanAuditStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = BedManagement.newDischargePlanAudit("code-538", title: "title-357")
        try item.moveTo(BedManagement.DischargePlanAuditStatus.draining)
        #expect(item.status == BedManagement.DischargePlanAuditStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newDischargePlanAudit("code-538", title: "title-357")
        item.status = BedManagement.DischargePlanAuditStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanAuditStatus.idle) }
    }
}
