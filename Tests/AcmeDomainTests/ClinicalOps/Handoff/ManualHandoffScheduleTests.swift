@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsManualHandoffScheduleTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newManualHandoffSchedule("code-204", label: "label-928")
        #expect(item.status == ClinicalOps.ManualHandoffScheduleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = ClinicalOps.newManualHandoffSchedule("code-204", label: "label-928")
        try item.moveTo(ClinicalOps.ManualHandoffScheduleStatus.inProgress)
        #expect(item.status == ClinicalOps.ManualHandoffScheduleStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newManualHandoffSchedule("code-204", label: "label-928")
        item.status = ClinicalOps.ManualHandoffScheduleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.ManualHandoffScheduleStatus.planned) }
    }
}
