@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskManifestTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newTaskManifest("code-186", label: "label-140")
        #expect(item.status == ClinicalOps.TaskManifestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = ClinicalOps.newTaskManifest("code-186", label: "label-140")
        try item.moveTo(ClinicalOps.TaskManifestStatus.failed)
        #expect(item.status == ClinicalOps.TaskManifestStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newTaskManifest("code-186", label: "label-140")
        item.status = ClinicalOps.TaskManifestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskManifestStatus.new) }
    }
}
