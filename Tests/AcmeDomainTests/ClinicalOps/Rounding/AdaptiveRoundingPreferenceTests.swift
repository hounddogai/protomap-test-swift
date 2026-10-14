@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveRoundingPreferenceTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newAdaptiveRoundingPreference("code-409", label: "label-947")
        #expect(item.status == ClinicalOps.AdaptiveRoundingPreferenceStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = ClinicalOps.newAdaptiveRoundingPreference("code-409", label: "label-947")
        try item.moveTo(ClinicalOps.AdaptiveRoundingPreferenceStatus.queued)
        #expect(item.status == ClinicalOps.AdaptiveRoundingPreferenceStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newAdaptiveRoundingPreference("code-409", label: "label-947")
        item.status = ClinicalOps.AdaptiveRoundingPreferenceStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AdaptiveRoundingPreferenceStatus.new) }
    }
}
