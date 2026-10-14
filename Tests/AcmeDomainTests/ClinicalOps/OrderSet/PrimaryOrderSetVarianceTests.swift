@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryOrderSetVarianceTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newPrimaryOrderSetVariance("code-328", name: "name-638")
        #expect(item.status == ClinicalOps.PrimaryOrderSetVarianceStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = ClinicalOps.newPrimaryOrderSetVariance("code-328", name: "name-638")
        try item.moveTo(ClinicalOps.PrimaryOrderSetVarianceStatus.queued)
        #expect(item.status == ClinicalOps.PrimaryOrderSetVarianceStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newPrimaryOrderSetVariance("code-328", name: "name-638")
        item.status = ClinicalOps.PrimaryOrderSetVarianceStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PrimaryOrderSetVarianceStatus.new) }
    }
}
