@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryWitnessOverrideTests {
    @Test func startsInDraft() throws {
        let item = Consent.newPrimaryWitnessOverride("code-577", title: "title-114")
        #expect(item.status == Consent.PrimaryWitnessOverrideStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Consent.newPrimaryWitnessOverride("code-577", title: "title-114")
        try item.moveTo(Consent.PrimaryWitnessOverrideStatus.active)
        #expect(item.status == Consent.PrimaryWitnessOverrideStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newPrimaryWitnessOverride("code-577", title: "title-114")
        item.status = Consent.PrimaryWitnessOverrideStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.PrimaryWitnessOverrideStatus.draft) }
    }
}
