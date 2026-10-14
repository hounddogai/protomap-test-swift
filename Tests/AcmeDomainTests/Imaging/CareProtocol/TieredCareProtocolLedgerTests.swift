@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredCareProtocolLedgerTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newTieredCareProtocolLedger("code-185", name: "name-767")
        #expect(item.status == Imaging.TieredCareProtocolLedgerStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Imaging.newTieredCareProtocolLedger("code-185", name: "name-767")
        try item.moveTo(Imaging.TieredCareProtocolLedgerStatus.stopped)
        #expect(item.status == Imaging.TieredCareProtocolLedgerStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newTieredCareProtocolLedger("code-185", name: "name-767")
        item.status = Imaging.TieredCareProtocolLedgerStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.TieredCareProtocolLedgerStatus.idle) }
    }
}
