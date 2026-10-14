@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierPreferenceTests {
    @Test func startsInIdle() throws {
        let item = Labs.newCourierPreference("code-784", title: "title-352")
        #expect(item.status == Labs.CourierPreferenceStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Labs.newCourierPreference("code-784", title: "title-352")
        try item.moveTo(Labs.CourierPreferenceStatus.warming)
        #expect(item.status == Labs.CourierPreferenceStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newCourierPreference("code-784", title: "title-352")
        item.status = Labs.CourierPreferenceStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierPreferenceStatus.idle) }
    }
}
