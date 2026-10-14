@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalAccessionScheduleTests {
    @Test func startsInCreated() throws {
        let item = Labs.newRegionalAccessionSchedule("code-559", title: "title-561")
        #expect(item.status == Labs.RegionalAccessionScheduleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Labs.newRegionalAccessionSchedule("code-559", title: "title-561")
        try item.moveTo(Labs.RegionalAccessionScheduleStatus.published)
        #expect(item.status == Labs.RegionalAccessionScheduleStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newRegionalAccessionSchedule("code-559", title: "title-561")
        item.status = Labs.RegionalAccessionScheduleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RegionalAccessionScheduleStatus.created) }
    }
}
