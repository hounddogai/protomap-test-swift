@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormMetricTests {
    @Test func startsInOpen() throws {
        let item = Consent.newConsentFormMetric("code-664", name: "name-333")
        #expect(item.status == Consent.ConsentFormMetricStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Consent.newConsentFormMetric("code-664", name: "name-333")
        try item.moveTo(Consent.ConsentFormMetricStatus.resolved)
        #expect(item.status == Consent.ConsentFormMetricStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newConsentFormMetric("code-664", name: "name-333")
        item.status = Consent.ConsentFormMetricStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormMetricStatus.`open`) }
    }
}
