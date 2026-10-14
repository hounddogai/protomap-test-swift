@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedDisclosurePreferenceTests {
    @Test func startsInCreated() throws {
        let item = Consent.newBatchedDisclosurePreference("code-669", label: "label-721")
        #expect(item.status == Consent.BatchedDisclosurePreferenceStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Consent.newBatchedDisclosurePreference("code-669", label: "label-721")
        try item.moveTo(Consent.BatchedDisclosurePreferenceStatus.published)
        #expect(item.status == Consent.BatchedDisclosurePreferenceStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newBatchedDisclosurePreference("code-669", label: "label-721")
        item.status = Consent.BatchedDisclosurePreferenceStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.BatchedDisclosurePreferenceStatus.created) }
    }
}
