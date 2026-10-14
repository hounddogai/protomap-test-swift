@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyLedgerTests {
    @Test func startsInNew() throws {
        let item = Imaging.newStudyLedger("code-2", label: "label-972")
        #expect(item.status == Imaging.StudyLedgerStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Imaging.newStudyLedger("code-2", label: "label-972")
        try item.moveTo(Imaging.StudyLedgerStatus.done)
        #expect(item.status == Imaging.StudyLedgerStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newStudyLedger("code-2", label: "label-972")
        item.status = Imaging.StudyLedgerStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyLedgerStatus.new) }
    }
}
