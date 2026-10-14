@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskProfileTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newTaskProfile("code-981", label: "label-805")
        #expect(item.status == ClinicalOps.TaskProfileStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = ClinicalOps.newTaskProfile("code-981", label: "label-805")
        try item.moveTo(ClinicalOps.TaskProfileStatus.failed)
        #expect(item.status == ClinicalOps.TaskProfileStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newTaskProfile("code-981", label: "label-805")
        item.status = ClinicalOps.TaskProfileStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskProfileStatus.new) }
    }
}
