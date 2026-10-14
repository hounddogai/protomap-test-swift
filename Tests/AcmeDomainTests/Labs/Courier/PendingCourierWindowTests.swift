@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingCourierWindowTests {
    @Test func startsInDraft() throws {
        let item = Labs.newPendingCourierWindow("code-900", name: "name-253")
        #expect(item.status == Labs.PendingCourierWindowStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Labs.newPendingCourierWindow("code-900", name: "name-253")
        try item.moveTo(Labs.PendingCourierWindowStatus.active)
        #expect(item.status == Labs.PendingCourierWindowStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newPendingCourierWindow("code-900", name: "name-253")
        item.status = Labs.PendingCourierWindowStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PendingCourierWindowStatus.draft) }
    }
}
