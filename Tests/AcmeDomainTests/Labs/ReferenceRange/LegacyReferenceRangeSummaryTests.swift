@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyReferenceRangeSummaryTests {
    @Test func startsInCreated() throws {
        let item = Labs.newLegacyReferenceRangeSummary("code-988", label: "label-126")
        #expect(item.status == Labs.LegacyReferenceRangeSummaryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newLegacyReferenceRangeSummary("code-988", label: "label-126")
        try item.moveTo(Labs.LegacyReferenceRangeSummaryStatus.validated)
        #expect(item.status == Labs.LegacyReferenceRangeSummaryStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newLegacyReferenceRangeSummary("code-988", label: "label-126")
        item.status = Labs.LegacyReferenceRangeSummaryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LegacyReferenceRangeSummaryStatus.created) }
    }
}
