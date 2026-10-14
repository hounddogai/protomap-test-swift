@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedConsentFormOverrideTests {
    @Test func startsInNew() throws {
        let item = Consent.newBatchedConsentFormOverride("code-957", title: "title-627")
        #expect(item.status == Consent.BatchedConsentFormOverrideStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Consent.newBatchedConsentFormOverride("code-957", title: "title-627")
        try item.moveTo(Consent.BatchedConsentFormOverrideStatus.running)
        #expect(item.status == Consent.BatchedConsentFormOverrideStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newBatchedConsentFormOverride("code-957", title: "title-627")
        item.status = Consent.BatchedConsentFormOverrideStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.BatchedConsentFormOverrideStatus.new) }
    }
}
