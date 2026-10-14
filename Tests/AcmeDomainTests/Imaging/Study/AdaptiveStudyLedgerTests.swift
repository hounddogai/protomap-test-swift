@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveStudyLedgerTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newAdaptiveStudyLedger("code-803", name: "name-938")
        #expect(item.status == Imaging.AdaptiveStudyLedgerStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Imaging.newAdaptiveStudyLedger("code-803", name: "name-938")
        try item.moveTo(Imaging.AdaptiveStudyLedgerStatus.closed)
        #expect(item.status == Imaging.AdaptiveStudyLedgerStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newAdaptiveStudyLedger("code-803", name: "name-938")
        item.status = Imaging.AdaptiveStudyLedgerStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.AdaptiveStudyLedgerStatus.draft) }
    }
}
