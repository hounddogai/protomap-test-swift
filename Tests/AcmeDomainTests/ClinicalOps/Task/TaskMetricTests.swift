@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskMetricTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newTaskMetric("code-649", title: "title-522")
        #expect(item.status == ClinicalOps.TaskMetricStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = ClinicalOps.newTaskMetric("code-649", title: "title-522")
        try item.moveTo(ClinicalOps.TaskMetricStatus.warming)
        #expect(item.status == ClinicalOps.TaskMetricStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newTaskMetric("code-649", title: "title-522")
        item.status = ClinicalOps.TaskMetricStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskMetricStatus.idle) }
    }
}
