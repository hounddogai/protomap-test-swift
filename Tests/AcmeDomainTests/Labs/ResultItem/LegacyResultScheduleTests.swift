@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyResultScheduleTests {
    @Test func startsInOpen() throws {
        let item = Labs.newLegacyResultSchedule("code-415", title: "title-547")
        #expect(item.status == Labs.LegacyResultScheduleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Labs.newLegacyResultSchedule("code-415", title: "title-547")
        try item.moveTo(Labs.LegacyResultScheduleStatus.reopened)
        #expect(item.status == Labs.LegacyResultScheduleStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newLegacyResultSchedule("code-415", title: "title-547")
        item.status = Labs.LegacyResultScheduleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LegacyResultScheduleStatus.`open`) }
    }
}
