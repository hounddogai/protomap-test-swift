@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskOverrideTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newTaskOverride("code-802", title: "title-364")
        #expect(item.status == ClinicalOps.TaskOverrideStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = ClinicalOps.newTaskOverride("code-802", title: "title-364")
        try item.moveTo(ClinicalOps.TaskOverrideStatus.queued)
        #expect(item.status == ClinicalOps.TaskOverrideStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newTaskOverride("code-802", title: "title-364")
        item.status = ClinicalOps.TaskOverrideStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskOverrideStatus.new) }
    }
}
