@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalHandoffScheduleTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newGlobalHandoffSchedule("code-945", name: "name-210")
        #expect(item.status == ClinicalOps.GlobalHandoffScheduleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = ClinicalOps.newGlobalHandoffSchedule("code-945", name: "name-210")
        try item.moveTo(ClinicalOps.GlobalHandoffScheduleStatus.resolved)
        #expect(item.status == ClinicalOps.GlobalHandoffScheduleStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newGlobalHandoffSchedule("code-945", name: "name-210")
        item.status = ClinicalOps.GlobalHandoffScheduleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.GlobalHandoffScheduleStatus.`open`) }
    }
}
