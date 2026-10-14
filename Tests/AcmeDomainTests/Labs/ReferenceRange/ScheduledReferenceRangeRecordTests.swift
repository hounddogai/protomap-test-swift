@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledReferenceRangeRecordTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newScheduledReferenceRangeRecord("code-551", label: "label-90")
        #expect(item.status == Labs.ScheduledReferenceRangeRecordStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Labs.newScheduledReferenceRangeRecord("code-551", label: "label-90")
        try item.moveTo(Labs.ScheduledReferenceRangeRecordStatus.inProgress)
        #expect(item.status == Labs.ScheduledReferenceRangeRecordStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newScheduledReferenceRangeRecord("code-551", label: "label-90")
        item.status = Labs.ScheduledReferenceRangeRecordStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ScheduledReferenceRangeRecordStatus.planned) }
    }
}
