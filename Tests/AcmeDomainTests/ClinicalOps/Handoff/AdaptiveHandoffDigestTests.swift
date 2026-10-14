@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveHandoffDigestTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newAdaptiveHandoffDigest("code-336", label: "label-356")
        #expect(item.status == ClinicalOps.AdaptiveHandoffDigestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = ClinicalOps.newAdaptiveHandoffDigest("code-336", label: "label-356")
        try item.moveTo(ClinicalOps.AdaptiveHandoffDigestStatus.expired)
        #expect(item.status == ClinicalOps.AdaptiveHandoffDigestStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newAdaptiveHandoffDigest("code-336", label: "label-356")
        item.status = ClinicalOps.AdaptiveHandoffDigestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AdaptiveHandoffDigestStatus.requested) }
    }
}
