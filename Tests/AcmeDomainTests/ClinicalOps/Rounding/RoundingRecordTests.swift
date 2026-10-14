@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingRecordTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newRoundingRecord("code-251", label: "label-608")
        #expect(item.status == ClinicalOps.RoundingRecordStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = ClinicalOps.newRoundingRecord("code-251", label: "label-608")
        try item.moveTo(ClinicalOps.RoundingRecordStatus.validated)
        #expect(item.status == ClinicalOps.RoundingRecordStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newRoundingRecord("code-251", label: "label-608")
        item.status = ClinicalOps.RoundingRecordStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingRecordStatus.created) }
    }
}
