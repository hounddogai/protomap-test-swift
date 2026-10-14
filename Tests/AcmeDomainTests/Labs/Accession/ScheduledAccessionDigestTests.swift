@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledAccessionDigestTests {
    @Test func startsInNew() throws {
        let item = Labs.newScheduledAccessionDigest("code-773", name: "name-657")
        #expect(item.status == Labs.ScheduledAccessionDigestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newScheduledAccessionDigest("code-773", name: "name-657")
        try item.moveTo(Labs.ScheduledAccessionDigestStatus.queued)
        #expect(item.status == Labs.ScheduledAccessionDigestStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newScheduledAccessionDigest("code-773", name: "name-657")
        item.status = Labs.ScheduledAccessionDigestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ScheduledAccessionDigestStatus.new) }
    }
}
