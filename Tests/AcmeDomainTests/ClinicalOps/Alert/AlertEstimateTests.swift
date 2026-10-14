@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertEstimateTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newAlertEstimate("code-108", label: "label-617")
        #expect(item.status == ClinicalOps.AlertEstimateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newAlertEstimate("code-108", label: "label-617")
        try item.moveTo(ClinicalOps.AlertEstimateStatus.granted)
        #expect(item.status == ClinicalOps.AlertEstimateStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newAlertEstimate("code-108", label: "label-617")
        item.status = ClinicalOps.AlertEstimateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertEstimateStatus.requested) }
    }
}
