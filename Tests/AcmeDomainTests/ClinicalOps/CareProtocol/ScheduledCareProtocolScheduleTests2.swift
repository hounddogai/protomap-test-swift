@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledCareProtocolScheduleTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newScheduledCareProtocolSchedule("code-827", name: "name-37")
        #expect(item.status == ClinicalOps.ScheduledCareProtocolScheduleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = ClinicalOps.newScheduledCareProtocolSchedule("code-827", name: "name-37")
        try item.moveTo(ClinicalOps.ScheduledCareProtocolScheduleStatus.active)
        #expect(item.status == ClinicalOps.ScheduledCareProtocolScheduleStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newScheduledCareProtocolSchedule("code-827", name: "name-37")
        item.status = ClinicalOps.ScheduledCareProtocolScheduleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.ScheduledCareProtocolScheduleStatus.draft) }
    }
}
