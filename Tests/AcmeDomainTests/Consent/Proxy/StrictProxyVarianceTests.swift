@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictProxyVarianceTests {
    @Test func startsInNew() throws {
        let item = Consent.newStrictProxyVariance("code-51", title: "title-297")
        #expect(item.status == Consent.StrictProxyVarianceStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Consent.newStrictProxyVariance("code-51", title: "title-297")
        try item.moveTo(Consent.StrictProxyVarianceStatus.queued)
        #expect(item.status == Consent.StrictProxyVarianceStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newStrictProxyVariance("code-51", title: "title-297")
        item.status = Consent.StrictProxyVarianceStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.StrictProxyVarianceStatus.new) }
    }
}
