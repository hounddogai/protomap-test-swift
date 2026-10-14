@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledCareProtocolSummaryTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newScheduledCareProtocolSummary("code-774", label: "label-649")
        #expect(item.status == Imaging.ScheduledCareProtocolSummaryStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Imaging.newScheduledCareProtocolSummary("code-774", label: "label-649")
        try item.moveTo(Imaging.ScheduledCareProtocolSummaryStatus.ready)
        #expect(item.status == Imaging.ScheduledCareProtocolSummaryStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newScheduledCareProtocolSummary("code-774", label: "label-649")
        item.status = Imaging.ScheduledCareProtocolSummaryStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ScheduledCareProtocolSummaryStatus.idle) }
    }
}
