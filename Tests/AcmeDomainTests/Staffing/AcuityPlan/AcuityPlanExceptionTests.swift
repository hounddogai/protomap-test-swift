@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanExceptionTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newAcuityPlanException("code-126", name: "name-538")
        #expect(item.status == Staffing.AcuityPlanExceptionStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Staffing.newAcuityPlanException("code-126", name: "name-538")
        try item.moveTo(Staffing.AcuityPlanExceptionStatus.scheduled)
        #expect(item.status == Staffing.AcuityPlanExceptionStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newAcuityPlanException("code-126", name: "name-538")
        item.status = Staffing.AcuityPlanExceptionStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanExceptionStatus.planned) }
    }
}
