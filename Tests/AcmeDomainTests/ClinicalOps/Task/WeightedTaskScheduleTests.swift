@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedTaskScheduleTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newWeightedTaskSchedule("code-629", title: "title-470")
        #expect(item.status == ClinicalOps.WeightedTaskScheduleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = ClinicalOps.newWeightedTaskSchedule("code-629", title: "title-470")
        try item.moveTo(ClinicalOps.WeightedTaskScheduleStatus.suspended)
        #expect(item.status == ClinicalOps.WeightedTaskScheduleStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newWeightedTaskSchedule("code-629", title: "title-470")
        item.status = ClinicalOps.WeightedTaskScheduleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.WeightedTaskScheduleStatus.draft) }
    }
}
