@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertDigestTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newAlertDigest("code-372", label: "label-275")
        #expect(item.status == ClinicalOps.AlertDigestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = ClinicalOps.newAlertDigest("code-372", label: "label-275")
        try item.moveTo(ClinicalOps.AlertDigestStatus.rejected)
        #expect(item.status == ClinicalOps.AlertDigestStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newAlertDigest("code-372", label: "label-275")
        item.status = ClinicalOps.AlertDigestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertDigestStatus.proposed) }
    }
}
