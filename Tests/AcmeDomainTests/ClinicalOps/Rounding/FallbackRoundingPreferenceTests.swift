@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackRoundingPreferenceTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newFallbackRoundingPreference("code-657", name: "name-350")
        #expect(item.status == ClinicalOps.FallbackRoundingPreferenceStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = ClinicalOps.newFallbackRoundingPreference("code-657", name: "name-350")
        try item.moveTo(ClinicalOps.FallbackRoundingPreferenceStatus.retired)
        #expect(item.status == ClinicalOps.FallbackRoundingPreferenceStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newFallbackRoundingPreference("code-657", name: "name-350")
        item.status = ClinicalOps.FallbackRoundingPreferenceStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.FallbackRoundingPreferenceStatus.created) }
    }
}
