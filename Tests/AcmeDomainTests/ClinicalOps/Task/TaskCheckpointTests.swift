@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskCheckpointTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newTaskCheckpoint("code-587", label: "label-115")
        #expect(item.status == ClinicalOps.TaskCheckpointStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = ClinicalOps.newTaskCheckpoint("code-587", label: "label-115")
        try item.moveTo(ClinicalOps.TaskCheckpointStatus.archived)
        #expect(item.status == ClinicalOps.TaskCheckpointStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newTaskCheckpoint("code-587", label: "label-115")
        item.status = ClinicalOps.TaskCheckpointStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskCheckpointStatus.`open`) }
    }
}
