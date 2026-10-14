@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingThresholdTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newRoundingThreshold("code-375", name: "name-49")
        #expect(item.status == ClinicalOps.RoundingThresholdStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = ClinicalOps.newRoundingThreshold("code-375", name: "name-49")
        try item.moveTo(ClinicalOps.RoundingThresholdStatus.suspended)
        #expect(item.status == ClinicalOps.RoundingThresholdStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newRoundingThreshold("code-375", name: "name-49")
        item.status = ClinicalOps.RoundingThresholdStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingThresholdStatus.draft) }
    }
}
