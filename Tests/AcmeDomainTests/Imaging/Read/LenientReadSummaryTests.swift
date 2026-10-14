@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientReadSummaryTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newLenientReadSummary("code-186", label: "label-614")
        #expect(item.status == Imaging.LenientReadSummaryStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Imaging.newLenientReadSummary("code-186", label: "label-614")
        try item.moveTo(Imaging.LenientReadSummaryStatus.draining)
        #expect(item.status == Imaging.LenientReadSummaryStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newLenientReadSummary("code-186", label: "label-614")
        item.status = Imaging.LenientReadSummaryStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.LenientReadSummaryStatus.idle) }
    }
}
