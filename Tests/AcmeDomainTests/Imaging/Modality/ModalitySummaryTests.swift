@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalitySummaryTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newModalitySummary("code-893", label: "label-54")
        #expect(item.status == Imaging.ModalitySummaryStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Imaging.newModalitySummary("code-893", label: "label-54")
        try item.moveTo(Imaging.ModalitySummaryStatus.scheduled)
        #expect(item.status == Imaging.ModalitySummaryStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newModalitySummary("code-893", label: "label-54")
        item.status = Imaging.ModalitySummaryStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalitySummaryStatus.planned) }
    }
}
