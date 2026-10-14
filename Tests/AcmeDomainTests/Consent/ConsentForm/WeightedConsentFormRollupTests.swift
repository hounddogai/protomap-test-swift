@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedConsentFormRollupTests {
    @Test func startsInCreated() throws {
        let item = Consent.newWeightedConsentFormRollup("code-405", title: "title-728")
        #expect(item.status == Consent.WeightedConsentFormRollupStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Consent.newWeightedConsentFormRollup("code-405", title: "title-728")
        try item.moveTo(Consent.WeightedConsentFormRollupStatus.published)
        #expect(item.status == Consent.WeightedConsentFormRollupStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newWeightedConsentFormRollup("code-405", title: "title-728")
        item.status = Consent.WeightedConsentFormRollupStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WeightedConsentFormRollupStatus.created) }
    }
}
