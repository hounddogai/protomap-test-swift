@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredCareProtocolSummaryTests {
    @Test func startsInNew() throws {
        let item = Imaging.newTieredCareProtocolSummary("code-462", name: "name-175")
        #expect(item.status == Imaging.TieredCareProtocolSummaryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Imaging.newTieredCareProtocolSummary("code-462", name: "name-175")
        try item.moveTo(Imaging.TieredCareProtocolSummaryStatus.running)
        #expect(item.status == Imaging.TieredCareProtocolSummaryStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newTieredCareProtocolSummary("code-462", name: "name-175")
        item.status = Imaging.TieredCareProtocolSummaryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.TieredCareProtocolSummaryStatus.new) }
    }
}
