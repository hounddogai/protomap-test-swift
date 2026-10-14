@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingAccessionMetricTests {
    @Test func startsInDraft() throws {
        let item = Labs.newPendingAccessionMetric("code-149", label: "label-682")
        #expect(item.status == Labs.PendingAccessionMetricStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newPendingAccessionMetric("code-149", label: "label-682")
        try item.moveTo(Labs.PendingAccessionMetricStatus.pending)
        #expect(item.status == Labs.PendingAccessionMetricStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newPendingAccessionMetric("code-149", label: "label-682")
        item.status = Labs.PendingAccessionMetricStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PendingAccessionMetricStatus.draft) }
    }
}
