@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingWitnessEntryTests {
    @Test func startsInRequested() throws {
        let item = Consent.newRollingWitnessEntry("code-374", name: "name-653")
        #expect(item.status == Consent.RollingWitnessEntryStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newRollingWitnessEntry("code-374", name: "name-653")
        try item.moveTo(Consent.RollingWitnessEntryStatus.granted)
        #expect(item.status == Consent.RollingWitnessEntryStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newRollingWitnessEntry("code-374", name: "name-653")
        item.status = Consent.RollingWitnessEntryStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RollingWitnessEntryStatus.requested) }
    }
}
