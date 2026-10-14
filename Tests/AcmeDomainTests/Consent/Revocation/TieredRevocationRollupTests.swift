@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredRevocationRollupTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newTieredRevocationRollup("code-239", label: "label-309")
        #expect(item.status == Consent.TieredRevocationRollupStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newTieredRevocationRollup("code-239", label: "label-309")
        try item.moveTo(Consent.TieredRevocationRollupStatus.scheduled)
        #expect(item.status == Consent.TieredRevocationRollupStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newTieredRevocationRollup("code-239", label: "label-309")
        item.status = Consent.TieredRevocationRollupStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.TieredRevocationRollupStatus.planned) }
    }
}
