@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanSlotTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newAcuityPlanSlot("code-58", label: "label-440")
        #expect(item.status == Staffing.AcuityPlanSlotStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newAcuityPlanSlot("code-58", label: "label-440")
        try item.moveTo(Staffing.AcuityPlanSlotStatus.approved)
        #expect(item.status == Staffing.AcuityPlanSlotStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newAcuityPlanSlot("code-58", label: "label-440")
        item.status = Staffing.AcuityPlanSlotStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanSlotStatus.proposed) }
    }
}
