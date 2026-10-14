@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierTierTests {
    @Test func startsInNew() throws {
        let item = Labs.newCourierTier("code-747", name: "name-673")
        #expect(item.status == Labs.CourierTierStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newCourierTier("code-747", name: "name-673")
        try item.moveTo(Labs.CourierTierStatus.queued)
        #expect(item.status == Labs.CourierTierStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newCourierTier("code-747", name: "name-673")
        item.status = Labs.CourierTierStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierTierStatus.new) }
    }
}
