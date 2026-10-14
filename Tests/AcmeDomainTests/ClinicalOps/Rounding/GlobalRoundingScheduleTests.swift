@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalRoundingScheduleTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newGlobalRoundingSchedule("code-658", label: "label-734")
        #expect(item.status == ClinicalOps.GlobalRoundingScheduleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newGlobalRoundingSchedule("code-658", label: "label-734")
        try item.moveTo(ClinicalOps.GlobalRoundingScheduleStatus.granted)
        #expect(item.status == ClinicalOps.GlobalRoundingScheduleStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newGlobalRoundingSchedule("code-658", label: "label-734")
        item.status = ClinicalOps.GlobalRoundingScheduleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.GlobalRoundingScheduleStatus.requested) }
    }
}
