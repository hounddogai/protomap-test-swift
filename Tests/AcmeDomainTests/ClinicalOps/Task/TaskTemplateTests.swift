@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskTemplateTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newTaskTemplate("code-395", name: "name-523")
        #expect(item.status == ClinicalOps.TaskTemplateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = ClinicalOps.newTaskTemplate("code-395", name: "name-523")
        try item.moveTo(ClinicalOps.TaskTemplateStatus.warming)
        #expect(item.status == ClinicalOps.TaskTemplateStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newTaskTemplate("code-395", name: "name-523")
        item.status = ClinicalOps.TaskTemplateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskTemplateStatus.idle) }
    }
}
