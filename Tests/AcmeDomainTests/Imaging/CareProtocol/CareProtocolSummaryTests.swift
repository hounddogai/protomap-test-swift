@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolSummaryTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newCareProtocolSummary("code-652", label: "label-362")
        #expect(item.status == Imaging.CareProtocolSummaryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Imaging.newCareProtocolSummary("code-652", label: "label-362")
        try item.moveTo(Imaging.CareProtocolSummaryStatus.active)
        #expect(item.status == Imaging.CareProtocolSummaryStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newCareProtocolSummary("code-652", label: "label-362")
        item.status = Imaging.CareProtocolSummaryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolSummaryStatus.draft) }
    }
}
