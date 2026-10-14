@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrioritySummaryTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newPrioritySummary("code-927", title: "title-351")
        #expect(item.status == Imaging.PrioritySummaryStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Imaging.newPrioritySummary("code-927", title: "title-351")
        try item.moveTo(Imaging.PrioritySummaryStatus.inProgress)
        #expect(item.status == Imaging.PrioritySummaryStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newPrioritySummary("code-927", title: "title-351")
        item.status = Imaging.PrioritySummaryStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PrioritySummaryStatus.planned) }
    }
}
