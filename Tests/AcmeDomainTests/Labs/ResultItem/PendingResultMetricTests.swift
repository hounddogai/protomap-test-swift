@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingResultMetricTests {
    @Test func startsInOpen() throws {
        let item = Labs.newPendingResultMetric("code-165", label: "label-670")
        #expect(item.status == Labs.PendingResultMetricStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Labs.newPendingResultMetric("code-165", label: "label-670")
        try item.moveTo(Labs.PendingResultMetricStatus.inReview)
        #expect(item.status == Labs.PendingResultMetricStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newPendingResultMetric("code-165", label: "label-670")
        item.status = Labs.PendingResultMetricStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PendingResultMetricStatus.`open`) }
    }
}
