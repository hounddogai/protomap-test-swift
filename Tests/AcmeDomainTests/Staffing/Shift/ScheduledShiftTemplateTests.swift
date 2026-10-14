@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledShiftTemplateTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newScheduledShiftTemplate("code-846", name: "name-417")
        #expect(item.status == Staffing.ScheduledShiftTemplateStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newScheduledShiftTemplate("code-846", name: "name-417")
        try item.moveTo(Staffing.ScheduledShiftTemplateStatus.rejected)
        #expect(item.status == Staffing.ScheduledShiftTemplateStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newScheduledShiftTemplate("code-846", name: "name-417")
        item.status = Staffing.ScheduledShiftTemplateStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ScheduledShiftTemplateStatus.proposed) }
    }
}
