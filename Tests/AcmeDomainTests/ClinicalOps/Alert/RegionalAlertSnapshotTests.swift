@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalAlertSnapshotTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newRegionalAlertSnapshot("code-285", label: "label-675")
        #expect(item.status == ClinicalOps.RegionalAlertSnapshotStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = ClinicalOps.newRegionalAlertSnapshot("code-285", label: "label-675")
        try item.moveTo(ClinicalOps.RegionalAlertSnapshotStatus.cancelled)
        #expect(item.status == ClinicalOps.RegionalAlertSnapshotStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newRegionalAlertSnapshot("code-285", label: "label-675")
        item.status = ClinicalOps.RegionalAlertSnapshotStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RegionalAlertSnapshotStatus.planned) }
    }
}
