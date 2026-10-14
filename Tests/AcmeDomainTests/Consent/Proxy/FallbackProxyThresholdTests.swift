@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackProxyThresholdTests {
    @Test func startsInNew() throws {
        let item = Consent.newFallbackProxyThreshold("code-952", name: "name-883")
        #expect(item.status == Consent.FallbackProxyThresholdStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Consent.newFallbackProxyThreshold("code-952", name: "name-883")
        try item.moveTo(Consent.FallbackProxyThresholdStatus.queued)
        #expect(item.status == Consent.FallbackProxyThresholdStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newFallbackProxyThreshold("code-952", name: "name-883")
        item.status = Consent.FallbackProxyThresholdStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.FallbackProxyThresholdStatus.new) }
    }
}
