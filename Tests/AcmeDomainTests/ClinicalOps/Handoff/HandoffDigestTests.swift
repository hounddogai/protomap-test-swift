@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffDigestTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newHandoffDigest("code-669", label: "label-429")
        #expect(item.status == ClinicalOps.HandoffDigestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = ClinicalOps.newHandoffDigest("code-669", label: "label-429")
        try item.moveTo(ClinicalOps.HandoffDigestStatus.pending)
        #expect(item.status == ClinicalOps.HandoffDigestStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newHandoffDigest("code-669", label: "label-429")
        item.status = ClinicalOps.HandoffDigestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffDigestStatus.draft) }
    }
}
