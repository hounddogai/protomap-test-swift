@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackModalityEntryTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newFallbackModalityEntry("code-716", name: "name-777")
        #expect(item.status == Imaging.FallbackModalityEntryStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Imaging.newFallbackModalityEntry("code-716", name: "name-777")
        try item.moveTo(Imaging.FallbackModalityEntryStatus.warming)
        #expect(item.status == Imaging.FallbackModalityEntryStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newFallbackModalityEntry("code-716", name: "name-777")
        item.status = Imaging.FallbackModalityEntryStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.FallbackModalityEntryStatus.idle) }
    }
}
