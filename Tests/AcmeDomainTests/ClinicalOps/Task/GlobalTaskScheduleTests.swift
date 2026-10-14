@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalTaskScheduleTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newGlobalTaskSchedule("code-562", label: "label-66")
        #expect(item.status == ClinicalOps.GlobalTaskScheduleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = ClinicalOps.newGlobalTaskSchedule("code-562", label: "label-66")
        try item.moveTo(ClinicalOps.GlobalTaskScheduleStatus.warming)
        #expect(item.status == ClinicalOps.GlobalTaskScheduleStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newGlobalTaskSchedule("code-562", label: "label-66")
        item.status = ClinicalOps.GlobalTaskScheduleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.GlobalTaskScheduleStatus.idle) }
    }
}
