@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadLedgerTests {
    @Test func startsInNew() throws {
        let item = Imaging.newReadLedger("code-430", title: "title-902")
        #expect(item.status == Imaging.ReadLedgerStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Imaging.newReadLedger("code-430", title: "title-902")
        try item.moveTo(Imaging.ReadLedgerStatus.queued)
        #expect(item.status == Imaging.ReadLedgerStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newReadLedger("code-430", title: "title-902")
        item.status = Imaging.ReadLedgerStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadLedgerStatus.new) }
    }
}
