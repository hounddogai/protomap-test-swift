@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyTaskRecordTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newLegacyTaskRecord("code-55", label: "label-566")
        #expect(item.status == ClinicalOps.LegacyTaskRecordStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = ClinicalOps.newLegacyTaskRecord("code-55", label: "label-566")
        try item.moveTo(ClinicalOps.LegacyTaskRecordStatus.completed)
        #expect(item.status == ClinicalOps.LegacyTaskRecordStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newLegacyTaskRecord("code-55", label: "label-566")
        item.status = ClinicalOps.LegacyTaskRecordStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.LegacyTaskRecordStatus.planned) }
    }
}
