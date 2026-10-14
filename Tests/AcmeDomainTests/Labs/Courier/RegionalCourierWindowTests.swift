@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalCourierWindowTests {
    @Test func startsInIdle() throws {
        let item = Labs.newRegionalCourierWindow("code-42", title: "title-922")
        #expect(item.status == Labs.RegionalCourierWindowStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Labs.newRegionalCourierWindow("code-42", title: "title-922")
        try item.moveTo(Labs.RegionalCourierWindowStatus.ready)
        #expect(item.status == Labs.RegionalCourierWindowStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newRegionalCourierWindow("code-42", title: "title-922")
        item.status = Labs.RegionalCourierWindowStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RegionalCourierWindowStatus.idle) }
    }
}
