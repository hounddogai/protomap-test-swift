@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskGroupTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newTaskGroup("code-781", title: "title-37")
        #expect(item.status == ClinicalOps.TaskGroupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = ClinicalOps.newTaskGroup("code-781", title: "title-37")
        try item.moveTo(ClinicalOps.TaskGroupStatus.done)
        #expect(item.status == ClinicalOps.TaskGroupStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newTaskGroup("code-781", title: "title-37")
        item.status = ClinicalOps.TaskGroupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskGroupStatus.new) }
    }
}
