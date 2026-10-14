@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryReferenceRangeScheduleTests {
    @Test func startsInNew() throws {
        let item = Labs.newPrimaryReferenceRangeSchedule("code-926", title: "title-277")
        #expect(item.status == Labs.PrimaryReferenceRangeScheduleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newPrimaryReferenceRangeSchedule("code-926", title: "title-277")
        try item.moveTo(Labs.PrimaryReferenceRangeScheduleStatus.queued)
        #expect(item.status == Labs.PrimaryReferenceRangeScheduleStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newPrimaryReferenceRangeSchedule("code-926", title: "title-277")
        item.status = Labs.PrimaryReferenceRangeScheduleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PrimaryReferenceRangeScheduleStatus.new) }
    }
}
