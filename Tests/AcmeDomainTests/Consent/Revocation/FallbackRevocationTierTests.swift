@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackRevocationTierTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newFallbackRevocationTier("code-249", label: "label-769")
        #expect(item.status == Consent.FallbackRevocationTierStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newFallbackRevocationTier("code-249", label: "label-769")
        try item.moveTo(Consent.FallbackRevocationTierStatus.scheduled)
        #expect(item.status == Consent.FallbackRevocationTierStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newFallbackRevocationTier("code-249", label: "label-769")
        item.status = Consent.FallbackRevocationTierStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.FallbackRevocationTierStatus.planned) }
    }
}
