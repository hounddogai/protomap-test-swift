@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetVarianceTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newOrderSetVariance("code-71", label: "label-131")
        #expect(item.status == ClinicalOps.OrderSetVarianceStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = ClinicalOps.newOrderSetVariance("code-71", label: "label-131")
        try item.moveTo(ClinicalOps.OrderSetVarianceStatus.resolved)
        #expect(item.status == ClinicalOps.OrderSetVarianceStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newOrderSetVariance("code-71", label: "label-131")
        item.status = ClinicalOps.OrderSetVarianceStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetVarianceStatus.`open`) }
    }
}
