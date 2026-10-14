@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityThresholdTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newPriorityThreshold("code-955", name: "name-900")
        #expect(item.status == Imaging.PriorityThresholdStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Imaging.newPriorityThreshold("code-955", name: "name-900")
        try item.moveTo(Imaging.PriorityThresholdStatus.suspended)
        #expect(item.status == Imaging.PriorityThresholdStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newPriorityThreshold("code-955", name: "name-900")
        item.status = Imaging.PriorityThresholdStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityThresholdStatus.draft) }
    }
}
