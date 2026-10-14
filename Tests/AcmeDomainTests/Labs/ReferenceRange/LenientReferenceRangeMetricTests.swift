@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientReferenceRangeMetricTests {
    @Test func startsInNew() throws {
        let item = Labs.newLenientReferenceRangeMetric("code-705", title: "title-531")
        #expect(item.status == Labs.LenientReferenceRangeMetricStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Labs.newLenientReferenceRangeMetric("code-705", title: "title-531")
        try item.moveTo(Labs.LenientReferenceRangeMetricStatus.failed)
        #expect(item.status == Labs.LenientReferenceRangeMetricStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newLenientReferenceRangeMetric("code-705", title: "title-531")
        item.status = Labs.LenientReferenceRangeMetricStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LenientReferenceRangeMetricStatus.new) }
    }
}
