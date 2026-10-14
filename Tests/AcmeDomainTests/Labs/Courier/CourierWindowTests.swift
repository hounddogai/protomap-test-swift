@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierWindowTests {
    @Test func startsInIdle() throws {
        let item = Labs.newCourierWindow("code-303", title: "title-349")
        #expect(item.status == Labs.CourierWindowStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Labs.newCourierWindow("code-303", title: "title-349")
        try item.moveTo(Labs.CourierWindowStatus.ready)
        #expect(item.status == Labs.CourierWindowStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newCourierWindow("code-303", title: "title-349")
        item.status = Labs.CourierWindowStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierWindowStatus.idle) }
    }
}
