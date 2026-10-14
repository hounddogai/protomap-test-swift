@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledLanguageLedgerTests {
    @Test func startsInIdle() throws {
        let item = Consent.newScheduledLanguageLedger("code-101", name: "name-526")
        #expect(item.status == Consent.ScheduledLanguageLedgerStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Consent.newScheduledLanguageLedger("code-101", name: "name-526")
        try item.moveTo(Consent.ScheduledLanguageLedgerStatus.ready)
        #expect(item.status == Consent.ScheduledLanguageLedgerStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newScheduledLanguageLedger("code-101", name: "name-526")
        item.status = Consent.ScheduledLanguageLedgerStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ScheduledLanguageLedgerStatus.idle) }
    }
}
