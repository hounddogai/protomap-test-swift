@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLegacyWitnessTierTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newLegacyWitnessTier("code-908", title: "title-36")
        #expect(item.status == Consent.LegacyWitnessTierStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newLegacyWitnessTier("code-908", title: "title-36")
        try item.moveTo(Consent.LegacyWitnessTierStatus.scheduled)
        #expect(item.status == Consent.LegacyWitnessTierStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newLegacyWitnessTier("code-908", title: "title-36")
        item.status = Consent.LegacyWitnessTierStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LegacyWitnessTierStatus.planned) }
    }
}
