@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessTargetTests {
    @Test func startsInCreated() throws {
        let item = Consent.newWitnessTarget("code-679", name: "name-715")
        #expect(item.status == Consent.WitnessTargetStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Consent.newWitnessTarget("code-679", name: "name-715")
        try item.moveTo(Consent.WitnessTargetStatus.published)
        #expect(item.status == Consent.WitnessTargetStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newWitnessTarget("code-679", name: "name-715")
        item.status = Consent.WitnessTargetStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessTargetStatus.created) }
    }
}
