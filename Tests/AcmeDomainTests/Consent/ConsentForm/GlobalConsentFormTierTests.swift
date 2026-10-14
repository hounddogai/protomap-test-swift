@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalConsentFormTierTests {
    @Test func startsInOpen() throws {
        let item = Consent.newGlobalConsentFormTier("code-999", name: "name-348")
        #expect(item.status == Consent.GlobalConsentFormTierStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Consent.newGlobalConsentFormTier("code-999", name: "name-348")
        try item.moveTo(Consent.GlobalConsentFormTierStatus.resolved)
        #expect(item.status == Consent.GlobalConsentFormTierStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newGlobalConsentFormTier("code-999", name: "name-348")
        item.status = Consent.GlobalConsentFormTierStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.GlobalConsentFormTierStatus.`open`) }
    }
}
