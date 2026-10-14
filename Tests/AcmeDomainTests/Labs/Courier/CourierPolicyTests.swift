@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierPolicyTests {
    @Test func startsInIdle() throws {
        let item = Labs.newCourierPolicy("code-675", name: "name-96")
        #expect(item.status == Labs.CourierPolicyStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Labs.newCourierPolicy("code-675", name: "name-96")
        try item.moveTo(Labs.CourierPolicyStatus.warming)
        #expect(item.status == Labs.CourierPolicyStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newCourierPolicy("code-675", name: "name-96")
        item.status = Labs.CourierPolicyStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierPolicyStatus.idle) }
    }
}
