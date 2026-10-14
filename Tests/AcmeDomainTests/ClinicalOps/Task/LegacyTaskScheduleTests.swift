@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyTaskScheduleTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newLegacyTaskSchedule("code-192", title: "title-430")
        #expect(item.status == ClinicalOps.LegacyTaskScheduleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = ClinicalOps.newLegacyTaskSchedule("code-192", title: "title-430")
        try item.moveTo(ClinicalOps.LegacyTaskScheduleStatus.validated)
        #expect(item.status == ClinicalOps.LegacyTaskScheduleStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newLegacyTaskSchedule("code-192", title: "title-430")
        item.status = ClinicalOps.LegacyTaskScheduleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.LegacyTaskScheduleStatus.created) }
    }
}
