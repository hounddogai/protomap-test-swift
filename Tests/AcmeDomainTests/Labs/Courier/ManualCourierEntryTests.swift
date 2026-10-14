@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualCourierEntryTests {
    @Test func startsInDraft() throws {
        let item = Labs.newManualCourierEntry("code-392", name: "name-914")
        #expect(item.status == Labs.ManualCourierEntryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Labs.newManualCourierEntry("code-392", name: "name-914")
        try item.moveTo(Labs.ManualCourierEntryStatus.closed)
        #expect(item.status == Labs.ManualCourierEntryStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newManualCourierEntry("code-392", name: "name-914")
        item.status = Labs.ManualCourierEntryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ManualCourierEntryStatus.draft) }
    }
}
