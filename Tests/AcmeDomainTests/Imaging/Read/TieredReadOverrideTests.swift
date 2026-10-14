@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredReadOverrideTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newTieredReadOverride("code-908", label: "label-266")
        #expect(item.status == Imaging.TieredReadOverrideStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newTieredReadOverride("code-908", label: "label-266")
        try item.moveTo(Imaging.TieredReadOverrideStatus.granted)
        #expect(item.status == Imaging.TieredReadOverrideStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newTieredReadOverride("code-908", label: "label-266")
        item.status = Imaging.TieredReadOverrideStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.TieredReadOverrideStatus.requested) }
    }
}
