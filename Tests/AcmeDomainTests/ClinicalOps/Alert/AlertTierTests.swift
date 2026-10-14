@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertTierTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newAlertTier("code-934", name: "name-572")
        #expect(item.status == ClinicalOps.AlertTierStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = ClinicalOps.newAlertTier("code-934", name: "name-572")
        try item.moveTo(ClinicalOps.AlertTierStatus.retired)
        #expect(item.status == ClinicalOps.AlertTierStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newAlertTier("code-934", name: "name-572")
        item.status = ClinicalOps.AlertTierStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertTierStatus.created) }
    }
}
