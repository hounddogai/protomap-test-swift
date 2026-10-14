@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeScheduleTests {
    @Test func startsInRequested() throws {
        let item = Labs.newReferenceRangeSchedule("code-816", name: "name-3")
        #expect(item.status == Labs.ReferenceRangeScheduleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Labs.newReferenceRangeSchedule("code-816", name: "name-3")
        try item.moveTo(Labs.ReferenceRangeScheduleStatus.granted)
        #expect(item.status == Labs.ReferenceRangeScheduleStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newReferenceRangeSchedule("code-816", name: "name-3")
        item.status = Labs.ReferenceRangeScheduleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeScheduleStatus.requested) }
    }
}
