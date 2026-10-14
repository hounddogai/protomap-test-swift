@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLenientOrderSetSnapshotTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newLenientOrderSetSnapshot("code-677", label: "label-423")
        #expect(item.status == ClinicalOps.LenientOrderSetSnapshotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = ClinicalOps.newLenientOrderSetSnapshot("code-677", label: "label-423")
        try item.moveTo(ClinicalOps.LenientOrderSetSnapshotStatus.failed)
        #expect(item.status == ClinicalOps.LenientOrderSetSnapshotStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newLenientOrderSetSnapshot("code-677", label: "label-423")
        item.status = ClinicalOps.LenientOrderSetSnapshotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.LenientOrderSetSnapshotStatus.new) }
    }
}
