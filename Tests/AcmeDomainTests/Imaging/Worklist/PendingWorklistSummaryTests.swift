@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingWorklistSummaryTests {
    @Test func startsInNew() throws {
        let item = Imaging.newPendingWorklistSummary("code-424", label: "label-188")
        #expect(item.status == Imaging.PendingWorklistSummaryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Imaging.newPendingWorklistSummary("code-424", label: "label-188")
        try item.moveTo(Imaging.PendingWorklistSummaryStatus.running)
        #expect(item.status == Imaging.PendingWorklistSummaryStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newPendingWorklistSummary("code-424", label: "label-188")
        item.status = Imaging.PendingWorklistSummaryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PendingWorklistSummaryStatus.new) }
    }
}
