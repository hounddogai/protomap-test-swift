@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictReferenceRangeScoreTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newStrictReferenceRangeScore("code-68", label: "label-130")
        #expect(item.status == Labs.StrictReferenceRangeScoreStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Labs.newStrictReferenceRangeScore("code-68", label: "label-130")
        try item.moveTo(Labs.StrictReferenceRangeScoreStatus.completed)
        #expect(item.status == Labs.StrictReferenceRangeScoreStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newStrictReferenceRangeScore("code-68", label: "label-130")
        item.status = Labs.StrictReferenceRangeScoreStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.StrictReferenceRangeScoreStatus.planned) }
    }
}
