@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictTaskPreferenceTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newStrictTaskPreference("code-850", label: "label-814")
        #expect(item.status == ClinicalOps.StrictTaskPreferenceStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = ClinicalOps.newStrictTaskPreference("code-850", label: "label-814")
        try item.moveTo(ClinicalOps.StrictTaskPreferenceStatus.done)
        #expect(item.status == ClinicalOps.StrictTaskPreferenceStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newStrictTaskPreference("code-850", label: "label-814")
        item.status = ClinicalOps.StrictTaskPreferenceStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.StrictTaskPreferenceStatus.new) }
    }
}
