@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskRuleTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newTaskRule("code-154", label: "label-460")
        #expect(item.status == ClinicalOps.TaskRuleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = ClinicalOps.newTaskRule("code-154", label: "label-460")
        try item.moveTo(ClinicalOps.TaskRuleStatus.reopened)
        #expect(item.status == ClinicalOps.TaskRuleStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newTaskRule("code-154", label: "label-460")
        item.status = ClinicalOps.TaskRuleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskRuleStatus.`open`) }
    }
}
