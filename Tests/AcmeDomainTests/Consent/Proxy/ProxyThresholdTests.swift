@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyThresholdTests {
    @Test func startsInNew() throws {
        let item = Consent.newProxyThreshold("code-418", title: "title-667")
        #expect(item.status == Consent.ProxyThresholdStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Consent.newProxyThreshold("code-418", title: "title-667")
        try item.moveTo(Consent.ProxyThresholdStatus.queued)
        #expect(item.status == Consent.ProxyThresholdStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newProxyThreshold("code-418", title: "title-667")
        item.status = Consent.ProxyThresholdStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyThresholdStatus.new) }
    }
}
