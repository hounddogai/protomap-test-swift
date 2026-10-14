@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeAdjustmentTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newOvertimeAdjustment("code-541", label: "label-910")
        #expect(item.status == Staffing.OvertimeAdjustmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newOvertimeAdjustment("code-541", label: "label-910")
        try item.moveTo(Staffing.OvertimeAdjustmentStatus.approved)
        #expect(item.status == Staffing.OvertimeAdjustmentStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newOvertimeAdjustment("code-541", label: "label-910")
        item.status = Staffing.OvertimeAdjustmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeAdjustmentStatus.proposed) }
    }
}
