@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskThresholdTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newTaskThreshold("code-692", name: "name-268")
        #expect(item.status == ClinicalOps.TaskThresholdStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = ClinicalOps.newTaskThreshold("code-692", name: "name-268")
        try item.moveTo(ClinicalOps.TaskThresholdStatus.published)
        #expect(item.status == ClinicalOps.TaskThresholdStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newTaskThreshold("code-692", name: "name-268")
        item.status = ClinicalOps.TaskThresholdStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskThresholdStatus.created) }
    }
}
