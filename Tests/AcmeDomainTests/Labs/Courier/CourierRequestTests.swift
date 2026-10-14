@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierRequestTests {
    @Test func startsInNew() throws {
        let item = Labs.newCourierRequest("code-563", title: "title-809")
        #expect(item.status == Labs.CourierRequestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newCourierRequest("code-563", title: "title-809")
        try item.moveTo(Labs.CourierRequestStatus.queued)
        #expect(item.status == Labs.CourierRequestStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newCourierRequest("code-563", title: "title-809")
        item.status = Labs.CourierRequestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierRequestStatus.new) }
    }
}
