@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptivePriorityOverrideTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newAdaptivePriorityOverride("code-361", label: "label-327")
        #expect(item.status == Imaging.AdaptivePriorityOverrideStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Imaging.newAdaptivePriorityOverride("code-361", label: "label-327")
        try item.moveTo(Imaging.AdaptivePriorityOverrideStatus.pending)
        #expect(item.status == Imaging.AdaptivePriorityOverrideStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newAdaptivePriorityOverride("code-361", label: "label-327")
        item.status = Imaging.AdaptivePriorityOverrideStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.AdaptivePriorityOverrideStatus.draft) }
    }
}
