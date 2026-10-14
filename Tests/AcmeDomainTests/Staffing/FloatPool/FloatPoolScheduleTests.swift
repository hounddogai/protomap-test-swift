@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolScheduleTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newFloatPoolSchedule("code-403", name: "name-385")
        #expect(item.status == Staffing.FloatPoolScheduleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Staffing.newFloatPoolSchedule("code-403", name: "name-385")
        try item.moveTo(Staffing.FloatPoolScheduleStatus.resolved)
        #expect(item.status == Staffing.FloatPoolScheduleStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newFloatPoolSchedule("code-403", name: "name-385")
        item.status = Staffing.FloatPoolScheduleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolScheduleStatus.`open`) }
    }
}
