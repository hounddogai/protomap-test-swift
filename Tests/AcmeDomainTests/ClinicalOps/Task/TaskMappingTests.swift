@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskMappingTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newTaskMapping("code-692", title: "title-116")
        #expect(item.status == ClinicalOps.TaskMappingStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = ClinicalOps.newTaskMapping("code-692", title: "title-116")
        try item.moveTo(ClinicalOps.TaskMappingStatus.validated)
        #expect(item.status == ClinicalOps.TaskMappingStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newTaskMapping("code-692", title: "title-116")
        item.status = ClinicalOps.TaskMappingStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskMappingStatus.created) }
    }
}
