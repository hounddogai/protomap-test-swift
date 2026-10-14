@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyCheckpointTests {
    @Test func startsInNew() throws {
        let item = Consent.newProxyCheckpoint("code-16", title: "title-215")
        #expect(item.status == Consent.ProxyCheckpointStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Consent.newProxyCheckpoint("code-16", title: "title-215")
        try item.moveTo(Consent.ProxyCheckpointStatus.queued)
        #expect(item.status == Consent.ProxyCheckpointStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newProxyCheckpoint("code-16", title: "title-215")
        item.status = Consent.ProxyCheckpointStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyCheckpointStatus.new) }
    }
}
