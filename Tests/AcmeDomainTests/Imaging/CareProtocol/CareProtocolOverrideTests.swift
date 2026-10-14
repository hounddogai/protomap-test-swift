@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolOverrideTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newCareProtocolOverride("code-769", label: "label-191")
        #expect(item.status == Imaging.CareProtocolOverrideStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Imaging.newCareProtocolOverride("code-769", label: "label-191")
        try item.moveTo(Imaging.CareProtocolOverrideStatus.suspended)
        #expect(item.status == Imaging.CareProtocolOverrideStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newCareProtocolOverride("code-769", label: "label-191")
        item.status = Imaging.CareProtocolOverrideStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolOverrideStatus.draft) }
    }
}
