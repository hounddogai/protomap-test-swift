@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalDisclosureLedgerTests {
    @Test func startsInNew() throws {
        let item = Consent.newSeasonalDisclosureLedger("code-926", label: "label-133")
        #expect(item.status == Consent.SeasonalDisclosureLedgerStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Consent.newSeasonalDisclosureLedger("code-926", label: "label-133")
        try item.moveTo(Consent.SeasonalDisclosureLedgerStatus.running)
        #expect(item.status == Consent.SeasonalDisclosureLedgerStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newSeasonalDisclosureLedger("code-926", label: "label-133")
        item.status = Consent.SeasonalDisclosureLedgerStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.SeasonalDisclosureLedgerStatus.new) }
    }
}
