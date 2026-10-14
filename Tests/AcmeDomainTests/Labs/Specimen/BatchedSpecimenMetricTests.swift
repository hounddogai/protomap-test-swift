@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedSpecimenMetricTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newBatchedSpecimenMetric("code-176", label: "label-349")
        #expect(item.status == Labs.BatchedSpecimenMetricStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Labs.newBatchedSpecimenMetric("code-176", label: "label-349")
        try item.moveTo(Labs.BatchedSpecimenMetricStatus.cancelled)
        #expect(item.status == Labs.BatchedSpecimenMetricStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newBatchedSpecimenMetric("code-176", label: "label-349")
        item.status = Labs.BatchedSpecimenMetricStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.BatchedSpecimenMetricStatus.planned) }
    }
}
