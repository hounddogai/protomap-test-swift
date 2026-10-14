@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLegacyDisclosureClaimTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newLegacyDisclosureClaim("code-155", label: "label-565")
        #expect(item.status == Consent.LegacyDisclosureClaimStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Consent.newLegacyDisclosureClaim("code-155", label: "label-565")
        try item.moveTo(Consent.LegacyDisclosureClaimStatus.cancelled)
        #expect(item.status == Consent.LegacyDisclosureClaimStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newLegacyDisclosureClaim("code-155", label: "label-565")
        item.status = Consent.LegacyDisclosureClaimStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LegacyDisclosureClaimStatus.planned) }
    }
}
