@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffVarianceTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newHandoffVariance("code-542", label: "label-792")
        #expect(item.status == ClinicalOps.HandoffVarianceStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = ClinicalOps.newHandoffVariance("code-542", label: "label-792")
        try item.moveTo(ClinicalOps.HandoffVarianceStatus.cancelled)
        #expect(item.status == ClinicalOps.HandoffVarianceStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newHandoffVariance("code-542", label: "label-792")
        item.status = ClinicalOps.HandoffVarianceStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffVarianceStatus.planned) }
    }
}
