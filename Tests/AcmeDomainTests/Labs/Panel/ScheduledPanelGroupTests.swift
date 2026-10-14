@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledPanelGroupTests {
    @Test func startsInNew() throws {
        let item = Labs.newScheduledPanelGroup("code-533", title: "title-759")
        #expect(item.status == Labs.ScheduledPanelGroupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newScheduledPanelGroup("code-533", title: "title-759")
        try item.moveTo(Labs.ScheduledPanelGroupStatus.queued)
        #expect(item.status == Labs.ScheduledPanelGroupStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newScheduledPanelGroup("code-533", title: "title-759")
        item.status = Labs.ScheduledPanelGroupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ScheduledPanelGroupStatus.new) }
    }
}
