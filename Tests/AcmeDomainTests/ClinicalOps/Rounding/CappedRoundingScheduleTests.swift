@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedRoundingScheduleTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newCappedRoundingSchedule("code-572", label: "label-419")
        #expect(item.status == ClinicalOps.CappedRoundingScheduleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = ClinicalOps.newCappedRoundingSchedule("code-572", label: "label-419")
        try item.moveTo(ClinicalOps.CappedRoundingScheduleStatus.inProgress)
        #expect(item.status == ClinicalOps.CappedRoundingScheduleStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newCappedRoundingSchedule("code-572", label: "label-419")
        item.status = ClinicalOps.CappedRoundingScheduleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CappedRoundingScheduleStatus.planned) }
    }
}
