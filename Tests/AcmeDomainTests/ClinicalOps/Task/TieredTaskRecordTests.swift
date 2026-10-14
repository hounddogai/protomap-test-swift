@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredTaskRecordTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newTieredTaskRecord("code-554", label: "label-908")
        #expect(item.status == ClinicalOps.TieredTaskRecordStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = ClinicalOps.newTieredTaskRecord("code-554", label: "label-908")
        try item.moveTo(ClinicalOps.TieredTaskRecordStatus.inProgress)
        #expect(item.status == ClinicalOps.TieredTaskRecordStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newTieredTaskRecord("code-554", label: "label-908")
        item.status = ClinicalOps.TieredTaskRecordStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TieredTaskRecordStatus.planned) }
    }
}
