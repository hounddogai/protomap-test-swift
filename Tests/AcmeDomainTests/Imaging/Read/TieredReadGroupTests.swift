@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredReadGroupTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newTieredReadGroup("code-630", name: "name-517")
        #expect(item.status == Imaging.TieredReadGroupStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Imaging.newTieredReadGroup("code-630", name: "name-517")
        try item.moveTo(Imaging.TieredReadGroupStatus.active)
        #expect(item.status == Imaging.TieredReadGroupStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newTieredReadGroup("code-630", name: "name-517")
        item.status = Imaging.TieredReadGroupStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.TieredReadGroupStatus.draft) }
    }
}
