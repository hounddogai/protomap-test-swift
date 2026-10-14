@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingTaskScheduleTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newPendingTaskSchedule("code-74", title: "title-198")
        #expect(item.status == ClinicalOps.PendingTaskScheduleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = ClinicalOps.newPendingTaskSchedule("code-74", title: "title-198")
        try item.moveTo(ClinicalOps.PendingTaskScheduleStatus.stopped)
        #expect(item.status == ClinicalOps.PendingTaskScheduleStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newPendingTaskSchedule("code-74", title: "title-198")
        item.status = ClinicalOps.PendingTaskScheduleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PendingTaskScheduleStatus.idle) }
    }
}
