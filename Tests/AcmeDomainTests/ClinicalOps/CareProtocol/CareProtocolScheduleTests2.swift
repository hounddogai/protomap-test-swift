@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolScheduleTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newCareProtocolSchedule("code-7", title: "title-210")
        #expect(item.status == ClinicalOps.CareProtocolScheduleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = ClinicalOps.newCareProtocolSchedule("code-7", title: "title-210")
        try item.moveTo(ClinicalOps.CareProtocolScheduleStatus.inProgress)
        #expect(item.status == ClinicalOps.CareProtocolScheduleStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newCareProtocolSchedule("code-7", title: "title-210")
        item.status = ClinicalOps.CareProtocolScheduleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolScheduleStatus.planned) }
    }
}
