@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyHandoffRequestTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newLegacyHandoffRequest("code-732", label: "label-236")
        #expect(item.status == ClinicalOps.LegacyHandoffRequestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = ClinicalOps.newLegacyHandoffRequest("code-732", label: "label-236")
        try item.moveTo(ClinicalOps.LegacyHandoffRequestStatus.suspended)
        #expect(item.status == ClinicalOps.LegacyHandoffRequestStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newLegacyHandoffRequest("code-732", label: "label-236")
        item.status = ClinicalOps.LegacyHandoffRequestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.LegacyHandoffRequestStatus.draft) }
    }
}
