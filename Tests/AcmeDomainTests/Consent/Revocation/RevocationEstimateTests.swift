@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationEstimateTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newRevocationEstimate("code-400", label: "label-292")
        #expect(item.status == Consent.RevocationEstimateStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newRevocationEstimate("code-400", label: "label-292")
        try item.moveTo(Consent.RevocationEstimateStatus.scheduled)
        #expect(item.status == Consent.RevocationEstimateStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newRevocationEstimate("code-400", label: "label-292")
        item.status = Consent.RevocationEstimateStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RevocationEstimateStatus.planned) }
    }
}
