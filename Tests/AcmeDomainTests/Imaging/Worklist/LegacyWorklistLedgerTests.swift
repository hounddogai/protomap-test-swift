@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyWorklistLedgerTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newLegacyWorklistLedger("code-636", label: "label-553")
        #expect(item.status == Imaging.LegacyWorklistLedgerStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Imaging.newLegacyWorklistLedger("code-636", label: "label-553")
        try item.moveTo(Imaging.LegacyWorklistLedgerStatus.closed)
        #expect(item.status == Imaging.LegacyWorklistLedgerStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newLegacyWorklistLedger("code-636", label: "label-553")
        item.status = Imaging.LegacyWorklistLedgerStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.LegacyWorklistLedgerStatus.draft) }
    }
}
