@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultWitnessPreferenceTests {
    @Test func startsInCreated() throws {
        let item = Consent.newDefaultWitnessPreference("code-912", name: "name-185")
        #expect(item.status == Consent.DefaultWitnessPreferenceStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Consent.newDefaultWitnessPreference("code-912", name: "name-185")
        try item.moveTo(Consent.DefaultWitnessPreferenceStatus.published)
        #expect(item.status == Consent.DefaultWitnessPreferenceStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newDefaultWitnessPreference("code-912", name: "name-185")
        item.status = Consent.DefaultWitnessPreferenceStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DefaultWitnessPreferenceStatus.created) }
    }
}
