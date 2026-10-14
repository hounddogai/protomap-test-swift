@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLegacyDisclosureThresholdTests {
    @Test func startsInOpen() throws {
        let item = Consent.newLegacyDisclosureThreshold("code-858", label: "label-946")
        #expect(item.status == Consent.LegacyDisclosureThresholdStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Consent.newLegacyDisclosureThreshold("code-858", label: "label-946")
        try item.moveTo(Consent.LegacyDisclosureThresholdStatus.resolved)
        #expect(item.status == Consent.LegacyDisclosureThresholdStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newLegacyDisclosureThreshold("code-858", label: "label-946")
        item.status = Consent.LegacyDisclosureThresholdStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LegacyDisclosureThresholdStatus.`open`) }
    }
}
