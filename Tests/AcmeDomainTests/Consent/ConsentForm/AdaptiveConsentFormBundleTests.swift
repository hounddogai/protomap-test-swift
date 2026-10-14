@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveConsentFormBundleTests {
    @Test func startsInOpen() throws {
        let item = Consent.newAdaptiveConsentFormBundle("code-844", title: "title-457")
        #expect(item.status == Consent.AdaptiveConsentFormBundleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Consent.newAdaptiveConsentFormBundle("code-844", title: "title-457")
        try item.moveTo(Consent.AdaptiveConsentFormBundleStatus.inReview)
        #expect(item.status == Consent.AdaptiveConsentFormBundleStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newAdaptiveConsentFormBundle("code-844", title: "title-457")
        item.status = Consent.AdaptiveConsentFormBundleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.AdaptiveConsentFormBundleStatus.`open`) }
    }
}
