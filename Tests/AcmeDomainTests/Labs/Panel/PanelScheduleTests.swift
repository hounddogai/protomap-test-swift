@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelScheduleTests {
    @Test func startsInCreated() throws {
        let item = Labs.newPanelSchedule("code-920", label: "label-996")
        #expect(item.status == Labs.PanelScheduleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newPanelSchedule("code-920", label: "label-996")
        try item.moveTo(Labs.PanelScheduleStatus.validated)
        #expect(item.status == Labs.PanelScheduleStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newPanelSchedule("code-920", label: "label-996")
        item.status = Labs.PanelScheduleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelScheduleStatus.created) }
    }
}
