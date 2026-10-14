@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLegacyDisclosureBaselineTests {
    @Test func startsInProposed() throws {
        let item = Consent.newLegacyDisclosureBaseline("code-143", name: "name-542")
        #expect(item.status == Consent.LegacyDisclosureBaselineStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Consent.newLegacyDisclosureBaseline("code-143", name: "name-542")
        try item.moveTo(Consent.LegacyDisclosureBaselineStatus.approved)
        #expect(item.status == Consent.LegacyDisclosureBaselineStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newLegacyDisclosureBaseline("code-143", name: "name-542")
        item.status = Consent.LegacyDisclosureBaselineStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LegacyDisclosureBaselineStatus.proposed) }
    }
}
