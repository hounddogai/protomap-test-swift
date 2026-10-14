@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingWorklistPreferenceTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newRollingWorklistPreference("code-748", name: "name-148")
        #expect(item.status == Imaging.RollingWorklistPreferenceStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Imaging.newRollingWorklistPreference("code-748", name: "name-148")
        try item.moveTo(Imaging.RollingWorklistPreferenceStatus.pending)
        #expect(item.status == Imaging.RollingWorklistPreferenceStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newRollingWorklistPreference("code-748", name: "name-148")
        item.status = Imaging.RollingWorklistPreferenceStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RollingWorklistPreferenceStatus.draft) }
    }
}
