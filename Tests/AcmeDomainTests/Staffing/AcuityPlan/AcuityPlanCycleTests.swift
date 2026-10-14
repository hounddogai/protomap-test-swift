@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanCycleTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newAcuityPlanCycle("code-596", name: "name-311")
        #expect(item.status == Staffing.AcuityPlanCycleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Staffing.newAcuityPlanCycle("code-596", name: "name-311")
        try item.moveTo(Staffing.AcuityPlanCycleStatus.inProgress)
        #expect(item.status == Staffing.AcuityPlanCycleStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newAcuityPlanCycle("code-596", name: "name-311")
        item.status = Staffing.AcuityPlanCycleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanCycleStatus.planned) }
    }
}
