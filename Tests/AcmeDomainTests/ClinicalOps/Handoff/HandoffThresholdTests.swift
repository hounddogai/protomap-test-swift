@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffThresholdTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newHandoffThreshold("code-111", title: "title-904")
        #expect(item.status == ClinicalOps.HandoffThresholdStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = ClinicalOps.newHandoffThreshold("code-111", title: "title-904")
        try item.moveTo(ClinicalOps.HandoffThresholdStatus.cancelled)
        #expect(item.status == ClinicalOps.HandoffThresholdStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newHandoffThreshold("code-111", title: "title-904")
        item.status = ClinicalOps.HandoffThresholdStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffThresholdStatus.planned) }
    }
}
