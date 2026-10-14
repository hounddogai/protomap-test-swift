@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedOrderSetTemplateTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newCappedOrderSetTemplate("code-975", name: "name-742")
        #expect(item.status == ClinicalOps.CappedOrderSetTemplateStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = ClinicalOps.newCappedOrderSetTemplate("code-975", name: "name-742")
        try item.moveTo(ClinicalOps.CappedOrderSetTemplateStatus.withdrawn)
        #expect(item.status == ClinicalOps.CappedOrderSetTemplateStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newCappedOrderSetTemplate("code-975", name: "name-742")
        item.status = ClinicalOps.CappedOrderSetTemplateStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CappedOrderSetTemplateStatus.proposed) }
    }
}
