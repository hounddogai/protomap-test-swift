@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingScheduleTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newRoundingSchedule("code-999", title: "title-301")
        #expect(item.status == ClinicalOps.RoundingScheduleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = ClinicalOps.newRoundingSchedule("code-999", title: "title-301")
        try item.moveTo(ClinicalOps.RoundingScheduleStatus.inProgress)
        #expect(item.status == ClinicalOps.RoundingScheduleStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newRoundingSchedule("code-999", title: "title-301")
        item.status = ClinicalOps.RoundingScheduleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingScheduleStatus.planned) }
    }
}
