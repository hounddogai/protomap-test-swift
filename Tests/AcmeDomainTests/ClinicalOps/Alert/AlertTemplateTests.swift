@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertTemplateTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newAlertTemplate("code-676", name: "name-341")
        #expect(item.status == ClinicalOps.AlertTemplateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = ClinicalOps.newAlertTemplate("code-676", name: "name-341")
        try item.moveTo(ClinicalOps.AlertTemplateStatus.done)
        #expect(item.status == ClinicalOps.AlertTemplateStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newAlertTemplate("code-676", name: "name-341")
        item.status = ClinicalOps.AlertTemplateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertTemplateStatus.new) }
    }
}
