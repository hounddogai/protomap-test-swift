@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertSnapshotTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newAlertSnapshot("code-861", label: "label-353")
        #expect(item.status == ClinicalOps.AlertSnapshotStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = ClinicalOps.newAlertSnapshot("code-861", label: "label-353")
        try item.moveTo(ClinicalOps.AlertSnapshotStatus.suspended)
        #expect(item.status == ClinicalOps.AlertSnapshotStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newAlertSnapshot("code-861", label: "label-353")
        item.status = ClinicalOps.AlertSnapshotStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertSnapshotStatus.draft) }
    }
}
