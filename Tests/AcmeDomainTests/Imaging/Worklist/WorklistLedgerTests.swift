@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistLedgerTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newWorklistLedger("code-939", name: "name-12")
        #expect(item.status == Imaging.WorklistLedgerStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Imaging.newWorklistLedger("code-939", name: "name-12")
        try item.moveTo(Imaging.WorklistLedgerStatus.inReview)
        #expect(item.status == Imaging.WorklistLedgerStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newWorklistLedger("code-939", name: "name-12")
        item.status = Imaging.WorklistLedgerStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistLedgerStatus.`open`) }
    }
}
