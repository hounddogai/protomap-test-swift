@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledAlertScheduleTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newScheduledAlertSchedule("code-312", title: "title-375")
        #expect(item.status == ClinicalOps.ScheduledAlertScheduleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = ClinicalOps.newScheduledAlertSchedule("code-312", title: "title-375")
        try item.moveTo(ClinicalOps.ScheduledAlertScheduleStatus.running)
        #expect(item.status == ClinicalOps.ScheduledAlertScheduleStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newScheduledAlertSchedule("code-312", title: "title-375")
        item.status = ClinicalOps.ScheduledAlertScheduleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.ScheduledAlertScheduleStatus.new) }
    }
}
