@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeScoreTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newReferenceRangeScore("code-816", label: "label-274")
        #expect(item.status == Labs.ReferenceRangeScoreStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Labs.newReferenceRangeScore("code-816", label: "label-274")
        try item.moveTo(Labs.ReferenceRangeScoreStatus.completed)
        #expect(item.status == Labs.ReferenceRangeScoreStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newReferenceRangeScore("code-816", label: "label-274")
        item.status = Labs.ReferenceRangeScoreStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeScoreStatus.planned) }
    }
}
