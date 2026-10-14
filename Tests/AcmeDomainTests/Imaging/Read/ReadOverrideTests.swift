@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadOverrideTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newReadOverride("code-977", label: "label-340")
        #expect(item.status == Imaging.ReadOverrideStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Imaging.newReadOverride("code-977", label: "label-340")
        try item.moveTo(Imaging.ReadOverrideStatus.suspended)
        #expect(item.status == Imaging.ReadOverrideStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newReadOverride("code-977", label: "label-340")
        item.status = Imaging.ReadOverrideStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadOverrideStatus.draft) }
    }
}
