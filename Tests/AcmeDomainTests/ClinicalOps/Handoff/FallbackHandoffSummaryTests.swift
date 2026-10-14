@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackHandoffSummaryTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newFallbackHandoffSummary("code-173", label: "label-70")
        #expect(item.status == ClinicalOps.FallbackHandoffSummaryStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newFallbackHandoffSummary("code-173", label: "label-70")
        try item.moveTo(ClinicalOps.FallbackHandoffSummaryStatus.granted)
        #expect(item.status == ClinicalOps.FallbackHandoffSummaryStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newFallbackHandoffSummary("code-173", label: "label-70")
        item.status = ClinicalOps.FallbackHandoffSummaryStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.FallbackHandoffSummaryStatus.requested) }
    }
}
