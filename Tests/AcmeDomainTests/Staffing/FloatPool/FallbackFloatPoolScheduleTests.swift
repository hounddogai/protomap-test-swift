@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackFloatPoolScheduleTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newFallbackFloatPoolSchedule("code-270", title: "title-865")
        #expect(item.status == Staffing.FallbackFloatPoolScheduleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Staffing.newFallbackFloatPoolSchedule("code-270", title: "title-865")
        try item.moveTo(Staffing.FallbackFloatPoolScheduleStatus.scheduled)
        #expect(item.status == Staffing.FallbackFloatPoolScheduleStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newFallbackFloatPoolSchedule("code-270", title: "title-865")
        item.status = Staffing.FallbackFloatPoolScheduleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FallbackFloatPoolScheduleStatus.planned) }
    }
}
