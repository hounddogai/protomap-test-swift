@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingPanelScheduleTests {
    @Test func startsInIdle() throws {
        let item = Labs.newRollingPanelSchedule("code-175", label: "label-865")
        #expect(item.status == Labs.RollingPanelScheduleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Labs.newRollingPanelSchedule("code-175", label: "label-865")
        try item.moveTo(Labs.RollingPanelScheduleStatus.warming)
        #expect(item.status == Labs.RollingPanelScheduleStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newRollingPanelSchedule("code-175", label: "label-865")
        item.status = Labs.RollingPanelScheduleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RollingPanelScheduleStatus.idle) }
    }
}
