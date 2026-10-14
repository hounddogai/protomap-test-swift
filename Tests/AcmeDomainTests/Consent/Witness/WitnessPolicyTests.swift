@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessPolicyTests {
    @Test func startsInDraft() throws {
        let item = Consent.newWitnessPolicy("code-12", label: "label-56")
        #expect(item.status == Consent.WitnessPolicyStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Consent.newWitnessPolicy("code-12", label: "label-56")
        try item.moveTo(Consent.WitnessPolicyStatus.active)
        #expect(item.status == Consent.WitnessPolicyStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newWitnessPolicy("code-12", label: "label-56")
        item.status = Consent.WitnessPolicyStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessPolicyStatus.draft) }
    }
}
