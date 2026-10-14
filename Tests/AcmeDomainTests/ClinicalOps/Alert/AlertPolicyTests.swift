@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertPolicyTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newAlertPolicy("code-202", name: "name-52")
        #expect(item.status == ClinicalOps.AlertPolicyStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = ClinicalOps.newAlertPolicy("code-202", name: "name-52")
        try item.moveTo(ClinicalOps.AlertPolicyStatus.draining)
        #expect(item.status == ClinicalOps.AlertPolicyStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newAlertPolicy("code-202", name: "name-52")
        item.status = ClinicalOps.AlertPolicyStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertPolicyStatus.idle) }
    }
}
