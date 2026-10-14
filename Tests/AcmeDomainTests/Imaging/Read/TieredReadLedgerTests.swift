@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredReadLedgerTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newTieredReadLedger("code-13", name: "name-724")
        #expect(item.status == Imaging.TieredReadLedgerStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Imaging.newTieredReadLedger("code-13", name: "name-724")
        try item.moveTo(Imaging.TieredReadLedgerStatus.draining)
        #expect(item.status == Imaging.TieredReadLedgerStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newTieredReadLedger("code-13", name: "name-724")
        item.status = Imaging.TieredReadLedgerStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.TieredReadLedgerStatus.idle) }
    }
}
