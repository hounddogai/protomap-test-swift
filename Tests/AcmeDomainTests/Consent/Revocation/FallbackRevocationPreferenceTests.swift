@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackRevocationPreferenceTests {
    @Test func startsInProposed() throws {
        let item = Consent.newFallbackRevocationPreference("code-379", name: "name-235")
        #expect(item.status == Consent.FallbackRevocationPreferenceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Consent.newFallbackRevocationPreference("code-379", name: "name-235")
        try item.moveTo(Consent.FallbackRevocationPreferenceStatus.approved)
        #expect(item.status == Consent.FallbackRevocationPreferenceStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newFallbackRevocationPreference("code-379", name: "name-235")
        item.status = Consent.FallbackRevocationPreferenceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.FallbackRevocationPreferenceStatus.proposed) }
    }
}
