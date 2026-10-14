@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientReferenceRangeSummaryTests {
    @Test func startsInIdle() throws {
        let item = Labs.newLenientReferenceRangeSummary("code-243", label: "label-662")
        #expect(item.status == Labs.LenientReferenceRangeSummaryStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Labs.newLenientReferenceRangeSummary("code-243", label: "label-662")
        try item.moveTo(Labs.LenientReferenceRangeSummaryStatus.warming)
        #expect(item.status == Labs.LenientReferenceRangeSummaryStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newLenientReferenceRangeSummary("code-243", label: "label-662")
        item.status = Labs.LenientReferenceRangeSummaryStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LenientReferenceRangeSummaryStatus.idle) }
    }
}
