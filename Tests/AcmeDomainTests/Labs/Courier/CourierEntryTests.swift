@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierEntryTests {
    @Test func startsInDraft() throws {
        let item = Labs.newCourierEntry("code-371", title: "title-450")
        #expect(item.status == Labs.CourierEntryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newCourierEntry("code-371", title: "title-450")
        try item.moveTo(Labs.CourierEntryStatus.pending)
        #expect(item.status == Labs.CourierEntryStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newCourierEntry("code-371", title: "title-450")
        item.status = Labs.CourierEntryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierEntryStatus.draft) }
    }
}
