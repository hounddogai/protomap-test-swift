@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveWorklistOverrideTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newAdaptiveWorklistOverride("code-85", label: "label-378")
        #expect(item.status == Imaging.AdaptiveWorklistOverrideStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Imaging.newAdaptiveWorklistOverride("code-85", label: "label-378")
        try item.moveTo(Imaging.AdaptiveWorklistOverrideStatus.active)
        #expect(item.status == Imaging.AdaptiveWorklistOverrideStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newAdaptiveWorklistOverride("code-85", label: "label-378")
        item.status = Imaging.AdaptiveWorklistOverrideStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.AdaptiveWorklistOverrideStatus.draft) }
    }
}
