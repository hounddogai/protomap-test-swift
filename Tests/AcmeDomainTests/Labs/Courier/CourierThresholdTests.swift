@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierThresholdTests {
    @Test func startsInRequested() throws {
        let item = Labs.newCourierThreshold("code-849", name: "name-859")
        #expect(item.status == Labs.CourierThresholdStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Labs.newCourierThreshold("code-849", name: "name-859")
        try item.moveTo(Labs.CourierThresholdStatus.granted)
        #expect(item.status == Labs.CourierThresholdStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newCourierThreshold("code-849", name: "name-859")
        item.status = Labs.CourierThresholdStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierThresholdStatus.requested) }
    }
}
