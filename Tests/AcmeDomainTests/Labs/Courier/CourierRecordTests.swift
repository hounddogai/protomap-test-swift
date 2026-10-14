@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierRecordTests {
    @Test func startsInIdle() throws {
        let item = Labs.newCourierRecord("code-524", name: "name-848")
        #expect(item.status == Labs.CourierRecordStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Labs.newCourierRecord("code-524", name: "name-848")
        try item.moveTo(Labs.CourierRecordStatus.warming)
        #expect(item.status == Labs.CourierRecordStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newCourierRecord("code-524", name: "name-848")
        item.status = Labs.CourierRecordStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierRecordStatus.idle) }
    }
}
