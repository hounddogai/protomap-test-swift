@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskTargetTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newTaskTarget("code-628", label: "label-160")
        #expect(item.status == ClinicalOps.TaskTargetStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = ClinicalOps.newTaskTarget("code-628", label: "label-160")
        try item.moveTo(ClinicalOps.TaskTargetStatus.ready)
        #expect(item.status == ClinicalOps.TaskTargetStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newTaskTarget("code-628", label: "label-160")
        item.status = ClinicalOps.TaskTargetStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskTargetStatus.idle) }
    }
}
