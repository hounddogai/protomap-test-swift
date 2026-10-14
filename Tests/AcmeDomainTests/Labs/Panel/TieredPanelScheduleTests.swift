@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsTieredPanelScheduleTests {
    @Test func startsInOpen() throws {
        let item = Labs.newTieredPanelSchedule("code-21", label: "label-478")
        #expect(item.status == Labs.TieredPanelScheduleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Labs.newTieredPanelSchedule("code-21", label: "label-478")
        try item.moveTo(Labs.TieredPanelScheduleStatus.inReview)
        #expect(item.status == Labs.TieredPanelScheduleStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newTieredPanelSchedule("code-21", label: "label-478")
        item.status = Labs.TieredPanelScheduleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.TieredPanelScheduleStatus.`open`) }
    }
}
