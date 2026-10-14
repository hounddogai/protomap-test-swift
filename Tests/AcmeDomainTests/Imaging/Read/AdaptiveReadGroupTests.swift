@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveReadGroupTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newAdaptiveReadGroup("code-461", name: "name-468")
        #expect(item.status == Imaging.AdaptiveReadGroupStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newAdaptiveReadGroup("code-461", name: "name-468")
        try item.moveTo(Imaging.AdaptiveReadGroupStatus.granted)
        #expect(item.status == Imaging.AdaptiveReadGroupStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newAdaptiveReadGroup("code-461", name: "name-468")
        item.status = Imaging.AdaptiveReadGroupStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.AdaptiveReadGroupStatus.requested) }
    }
}
