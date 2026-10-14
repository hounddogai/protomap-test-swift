@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryCourierDigestTests {
    @Test func startsInNew() throws {
        let item = Labs.newPrimaryCourierDigest("code-177", title: "title-297")
        #expect(item.status == Labs.PrimaryCourierDigestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newPrimaryCourierDigest("code-177", title: "title-297")
        try item.moveTo(Labs.PrimaryCourierDigestStatus.queued)
        #expect(item.status == Labs.PrimaryCourierDigestStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newPrimaryCourierDigest("code-177", title: "title-297")
        item.status = Labs.PrimaryCourierDigestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PrimaryCourierDigestStatus.new) }
    }
}
