@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingPreferenceTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newRoundingPreference("code-182", label: "label-669")
        #expect(item.status == ClinicalOps.RoundingPreferenceStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = ClinicalOps.newRoundingPreference("code-182", label: "label-669")
        try item.moveTo(ClinicalOps.RoundingPreferenceStatus.pending)
        #expect(item.status == ClinicalOps.RoundingPreferenceStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newRoundingPreference("code-182", label: "label-669")
        item.status = ClinicalOps.RoundingPreferenceStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingPreferenceStatus.draft) }
    }
}
