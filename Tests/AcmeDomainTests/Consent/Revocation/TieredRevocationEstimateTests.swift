@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredRevocationEstimateTests {
    @Test func startsInDraft() throws {
        let item = Consent.newTieredRevocationEstimate("code-877", label: "label-612")
        #expect(item.status == Consent.TieredRevocationEstimateStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Consent.newTieredRevocationEstimate("code-877", label: "label-612")
        try item.moveTo(Consent.TieredRevocationEstimateStatus.active)
        #expect(item.status == Consent.TieredRevocationEstimateStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newTieredRevocationEstimate("code-877", label: "label-612")
        item.status = Consent.TieredRevocationEstimateStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.TieredRevocationEstimateStatus.draft) }
    }
}
