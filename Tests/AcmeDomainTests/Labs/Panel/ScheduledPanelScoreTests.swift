@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledPanelScoreTests {
    @Test func startsInIdle() throws {
        let item = Labs.newScheduledPanelScore("code-812", name: "name-687")
        #expect(item.status == Labs.ScheduledPanelScoreStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Labs.newScheduledPanelScore("code-812", name: "name-687")
        try item.moveTo(Labs.ScheduledPanelScoreStatus.stopped)
        #expect(item.status == Labs.ScheduledPanelScoreStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newScheduledPanelScore("code-812", name: "name-687")
        item.status = Labs.ScheduledPanelScoreStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ScheduledPanelScoreStatus.idle) }
    }
}
