@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredReadTierTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newTieredReadTier("code-557", title: "title-968")
        #expect(item.status == Imaging.TieredReadTierStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Imaging.newTieredReadTier("code-557", title: "title-968")
        try item.moveTo(Imaging.TieredReadTierStatus.draining)
        #expect(item.status == Imaging.TieredReadTierStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newTieredReadTier("code-557", title: "title-968")
        item.status = Imaging.TieredReadTierStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.TieredReadTierStatus.idle) }
    }
}
