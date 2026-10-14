@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyOrderSetEntryTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newLegacyOrderSetEntry("code-28", label: "label-81")
        #expect(item.status == ClinicalOps.LegacyOrderSetEntryStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = ClinicalOps.newLegacyOrderSetEntry("code-28", label: "label-81")
        try item.moveTo(ClinicalOps.LegacyOrderSetEntryStatus.withdrawn)
        #expect(item.status == ClinicalOps.LegacyOrderSetEntryStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newLegacyOrderSetEntry("code-28", label: "label-81")
        item.status = ClinicalOps.LegacyOrderSetEntryStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.LegacyOrderSetEntryStatus.proposed) }
    }
}
