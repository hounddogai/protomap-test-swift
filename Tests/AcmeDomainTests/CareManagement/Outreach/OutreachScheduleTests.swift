@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachScheduleTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newOutreachSchedule("code-311", name: "name-775")
        #expect(item.status == CareManagement.OutreachScheduleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = CareManagement.newOutreachSchedule("code-311", name: "name-775")
        try item.moveTo(CareManagement.OutreachScheduleStatus.scheduled)
        #expect(item.status == CareManagement.OutreachScheduleStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newOutreachSchedule("code-311", name: "name-775")
        item.status = CareManagement.OutreachScheduleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachScheduleStatus.planned) }
    }
}
