@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskScheduleTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newTaskSchedule("code-651", name: "name-262")
        #expect(item.status == ClinicalOps.TaskScheduleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = ClinicalOps.newTaskSchedule("code-651", name: "name-262")
        try item.moveTo(ClinicalOps.TaskScheduleStatus.active)
        #expect(item.status == ClinicalOps.TaskScheduleStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newTaskSchedule("code-651", name: "name-262")
        item.status = ClinicalOps.TaskScheduleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskScheduleStatus.draft) }
    }
}
