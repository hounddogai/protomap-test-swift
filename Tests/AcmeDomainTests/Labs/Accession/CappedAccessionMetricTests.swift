@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedAccessionMetricTests {
    @Test func startsInNew() throws {
        let item = Labs.newCappedAccessionMetric("code-101", title: "title-470")
        #expect(item.status == Labs.CappedAccessionMetricStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newCappedAccessionMetric("code-101", title: "title-470")
        try item.moveTo(Labs.CappedAccessionMetricStatus.queued)
        #expect(item.status == Labs.CappedAccessionMetricStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newCappedAccessionMetric("code-101", title: "title-470")
        item.status = Labs.CappedAccessionMetricStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CappedAccessionMetricStatus.new) }
    }
}
