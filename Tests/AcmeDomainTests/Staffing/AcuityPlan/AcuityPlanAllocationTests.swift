@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanAllocationTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newAcuityPlanAllocation("code-148", title: "title-542")
        #expect(item.status == Staffing.AcuityPlanAllocationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newAcuityPlanAllocation("code-148", title: "title-542")
        try item.moveTo(Staffing.AcuityPlanAllocationStatus.granted)
        #expect(item.status == Staffing.AcuityPlanAllocationStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newAcuityPlanAllocation("code-148", title: "title-542")
        item.status = Staffing.AcuityPlanAllocationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanAllocationStatus.requested) }
    }
}
