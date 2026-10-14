@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalShiftTemplateTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newGlobalShiftTemplate("code-606", label: "label-987")
        #expect(item.status == Staffing.GlobalShiftTemplateStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Staffing.newGlobalShiftTemplate("code-606", label: "label-987")
        try item.moveTo(Staffing.GlobalShiftTemplateStatus.inProgress)
        #expect(item.status == Staffing.GlobalShiftTemplateStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newGlobalShiftTemplate("code-606", label: "label-987")
        item.status = Staffing.GlobalShiftTemplateStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.GlobalShiftTemplateStatus.planned) }
    }
}
