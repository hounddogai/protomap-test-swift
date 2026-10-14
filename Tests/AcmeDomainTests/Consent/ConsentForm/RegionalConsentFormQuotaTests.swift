@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalConsentFormQuotaTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newRegionalConsentFormQuota("code-768", title: "title-444")
        #expect(item.status == Consent.RegionalConsentFormQuotaStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newRegionalConsentFormQuota("code-768", title: "title-444")
        try item.moveTo(Consent.RegionalConsentFormQuotaStatus.scheduled)
        #expect(item.status == Consent.RegionalConsentFormQuotaStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newRegionalConsentFormQuota("code-768", title: "title-444")
        item.status = Consent.RegionalConsentFormQuotaStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RegionalConsentFormQuotaStatus.planned) }
    }
}
