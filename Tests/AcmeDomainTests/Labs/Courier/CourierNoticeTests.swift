@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierNoticeTests {
    @Test func startsInIdle() throws {
        let item = Labs.newCourierNotice("code-522", name: "name-837")
        #expect(item.status == Labs.CourierNoticeStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Labs.newCourierNotice("code-522", name: "name-837")
        try item.moveTo(Labs.CourierNoticeStatus.draining)
        #expect(item.status == Labs.CourierNoticeStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newCourierNotice("code-522", name: "name-837")
        item.status = Labs.CourierNoticeStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierNoticeStatus.idle) }
    }
}
