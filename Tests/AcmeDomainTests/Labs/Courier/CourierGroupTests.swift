@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierGroupTests {
    @Test func startsInDraft() throws {
        let item = Labs.newCourierGroup("code-172", title: "title-214")
        #expect(item.status == Labs.CourierGroupStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Labs.newCourierGroup("code-172", title: "title-214")
        try item.moveTo(Labs.CourierGroupStatus.active)
        #expect(item.status == Labs.CourierGroupStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newCourierGroup("code-172", title: "title-214")
        item.status = Labs.CourierGroupStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierGroupStatus.draft) }
    }
}
