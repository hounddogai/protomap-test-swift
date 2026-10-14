@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetTemplateTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newOrderSetTemplate("code-769", label: "label-568")
        #expect(item.status == ClinicalOps.OrderSetTemplateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = ClinicalOps.newOrderSetTemplate("code-769", label: "label-568")
        try item.moveTo(ClinicalOps.OrderSetTemplateStatus.failed)
        #expect(item.status == ClinicalOps.OrderSetTemplateStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newOrderSetTemplate("code-769", label: "label-568")
        item.status = ClinicalOps.OrderSetTemplateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetTemplateStatus.new) }
    }
}
