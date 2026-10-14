@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsManualAlertScoreTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newManualAlertScore("code-327", label: "label-874")
        #expect(item.status == ClinicalOps.ManualAlertScoreStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newManualAlertScore("code-327", label: "label-874")
        try item.moveTo(ClinicalOps.ManualAlertScoreStatus.granted)
        #expect(item.status == ClinicalOps.ManualAlertScoreStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newManualAlertScore("code-327", label: "label-874")
        item.status = ClinicalOps.ManualAlertScoreStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.ManualAlertScoreStatus.requested) }
    }
}
