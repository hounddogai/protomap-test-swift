@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingTaskPolicyTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newRollingTaskPolicy("code-480", label: "label-874")
        #expect(item.status == ClinicalOps.RollingTaskPolicyStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = ClinicalOps.newRollingTaskPolicy("code-480", label: "label-874")
        try item.moveTo(ClinicalOps.RollingTaskPolicyStatus.validated)
        #expect(item.status == ClinicalOps.RollingTaskPolicyStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newRollingTaskPolicy("code-480", label: "label-874")
        item.status = ClinicalOps.RollingTaskPolicyStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RollingTaskPolicyStatus.created) }
    }
}
