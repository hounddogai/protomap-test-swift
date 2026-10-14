@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanRecordTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newAcuityPlanRecord("code-145", label: "label-864")
        #expect(item.status == Staffing.AcuityPlanRecordStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Staffing.newAcuityPlanRecord("code-145", label: "label-864")
        try item.moveTo(Staffing.AcuityPlanRecordStatus.completed)
        #expect(item.status == Staffing.AcuityPlanRecordStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newAcuityPlanRecord("code-145", label: "label-864")
        item.status = Staffing.AcuityPlanRecordStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanRecordStatus.planned) }
    }
}
