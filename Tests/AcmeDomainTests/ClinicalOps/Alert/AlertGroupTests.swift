@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertGroupTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newAlertGroup("code-378", label: "label-512")
        #expect(item.status == ClinicalOps.AlertGroupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = ClinicalOps.newAlertGroup("code-378", label: "label-512")
        try item.moveTo(ClinicalOps.AlertGroupStatus.failed)
        #expect(item.status == ClinicalOps.AlertGroupStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newAlertGroup("code-378", label: "label-512")
        item.status = ClinicalOps.AlertGroupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertGroupStatus.new) }
    }
}
