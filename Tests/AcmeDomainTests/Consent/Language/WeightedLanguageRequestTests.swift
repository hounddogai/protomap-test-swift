@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedLanguageRequestTests {
    @Test func startsInCreated() throws {
        let item = Consent.newWeightedLanguageRequest("code-103", title: "title-134")
        #expect(item.status == Consent.WeightedLanguageRequestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Consent.newWeightedLanguageRequest("code-103", title: "title-134")
        try item.moveTo(Consent.WeightedLanguageRequestStatus.published)
        #expect(item.status == Consent.WeightedLanguageRequestStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newWeightedLanguageRequest("code-103", title: "title-134")
        item.status = Consent.WeightedLanguageRequestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WeightedLanguageRequestStatus.created) }
    }
}
