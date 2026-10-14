@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredReadTargetTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newTieredReadTarget("code-14", title: "title-565")
        #expect(item.status == Imaging.TieredReadTargetStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Imaging.newTieredReadTarget("code-14", title: "title-565")
        try item.moveTo(Imaging.TieredReadTargetStatus.expired)
        #expect(item.status == Imaging.TieredReadTargetStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newTieredReadTarget("code-14", title: "title-565")
        item.status = Imaging.TieredReadTargetStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.TieredReadTargetStatus.requested) }
    }
}
