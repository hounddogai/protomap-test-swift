@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictProxyBaselineTests {
    @Test func startsInProposed() throws {
        let item = Consent.newStrictProxyBaseline("code-508", title: "title-44")
        #expect(item.status == Consent.StrictProxyBaselineStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Consent.newStrictProxyBaseline("code-508", title: "title-44")
        try item.moveTo(Consent.StrictProxyBaselineStatus.rejected)
        #expect(item.status == Consent.StrictProxyBaselineStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newStrictProxyBaseline("code-508", title: "title-44")
        item.status = Consent.StrictProxyBaselineStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.StrictProxyBaselineStatus.proposed) }
    }
}
