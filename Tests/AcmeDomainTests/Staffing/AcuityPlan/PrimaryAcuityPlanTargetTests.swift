@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryAcuityPlanTargetTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newPrimaryAcuityPlanTarget("code-593", title: "title-363")
        #expect(item.status == Staffing.PrimaryAcuityPlanTargetStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Staffing.newPrimaryAcuityPlanTarget("code-593", title: "title-363")
        try item.moveTo(Staffing.PrimaryAcuityPlanTargetStatus.validated)
        #expect(item.status == Staffing.PrimaryAcuityPlanTargetStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newPrimaryAcuityPlanTarget("code-593", title: "title-363")
        item.status = Staffing.PrimaryAcuityPlanTargetStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PrimaryAcuityPlanTargetStatus.created) }
    }
}
