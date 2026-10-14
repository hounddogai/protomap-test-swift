@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingVarianceTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newRoundingVariance("code-118", title: "title-27")
        #expect(item.status == ClinicalOps.RoundingVarianceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = ClinicalOps.newRoundingVariance("code-118", title: "title-27")
        try item.moveTo(ClinicalOps.RoundingVarianceStatus.withdrawn)
        #expect(item.status == ClinicalOps.RoundingVarianceStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newRoundingVariance("code-118", title: "title-27")
        item.status = ClinicalOps.RoundingVarianceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingVarianceStatus.proposed) }
    }
}
