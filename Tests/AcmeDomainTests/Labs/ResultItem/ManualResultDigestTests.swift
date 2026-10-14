@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualResultDigestTests {
    @Test func startsInIdle() throws {
        let item = Labs.newManualResultDigest("code-885", title: "title-570")
        #expect(item.status == Labs.ManualResultDigestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Labs.newManualResultDigest("code-885", title: "title-570")
        try item.moveTo(Labs.ManualResultDigestStatus.ready)
        #expect(item.status == Labs.ManualResultDigestStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newManualResultDigest("code-885", title: "title-570")
        item.status = Labs.ManualResultDigestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ManualResultDigestStatus.idle) }
    }
}
