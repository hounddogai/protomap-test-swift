@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormQuotaTests {
    @Test func startsInIdle() throws {
        let item = Consent.newConsentFormQuota("code-26", title: "title-579")
        #expect(item.status == Consent.ConsentFormQuotaStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Consent.newConsentFormQuota("code-26", title: "title-579")
        try item.moveTo(Consent.ConsentFormQuotaStatus.warming)
        #expect(item.status == Consent.ConsentFormQuotaStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newConsentFormQuota("code-26", title: "title-579")
        item.status = Consent.ConsentFormQuotaStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormQuotaStatus.idle) }
    }
}
