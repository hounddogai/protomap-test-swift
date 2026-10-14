@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierProfileTests {
    @Test func startsInIdle() throws {
        let item = Labs.newCourierProfile("code-173", title: "title-62")
        #expect(item.status == Labs.CourierProfileStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Labs.newCourierProfile("code-173", title: "title-62")
        try item.moveTo(Labs.CourierProfileStatus.warming)
        #expect(item.status == Labs.CourierProfileStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newCourierProfile("code-173", title: "title-62")
        item.status = Labs.CourierProfileStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierProfileStatus.idle) }
    }
}
