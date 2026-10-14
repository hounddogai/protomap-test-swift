@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingSpecimenMetricTests {
    @Test func startsInDraft() throws {
        let item = Labs.newPendingSpecimenMetric("code-771", label: "label-856")
        #expect(item.status == Labs.PendingSpecimenMetricStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Labs.newPendingSpecimenMetric("code-771", label: "label-856")
        try item.moveTo(Labs.PendingSpecimenMetricStatus.suspended)
        #expect(item.status == Labs.PendingSpecimenMetricStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newPendingSpecimenMetric("code-771", label: "label-856")
        item.status = Labs.PendingSpecimenMetricStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PendingSpecimenMetricStatus.draft) }
    }
}
