@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalAlertTargetTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newGlobalAlertTarget("code-784", label: "label-341")
        #expect(item.status == ClinicalOps.GlobalAlertTargetStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = ClinicalOps.newGlobalAlertTarget("code-784", label: "label-341")
        try item.moveTo(ClinicalOps.GlobalAlertTargetStatus.retired)
        #expect(item.status == ClinicalOps.GlobalAlertTargetStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newGlobalAlertTarget("code-784", label: "label-341")
        item.status = ClinicalOps.GlobalAlertTargetStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.GlobalAlertTargetStatus.created) }
    }
}
