@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveHandoffVarianceTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newAdaptiveHandoffVariance("code-115", label: "label-680")
        #expect(item.status == ClinicalOps.AdaptiveHandoffVarianceStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = ClinicalOps.newAdaptiveHandoffVariance("code-115", label: "label-680")
        try item.moveTo(ClinicalOps.AdaptiveHandoffVarianceStatus.running)
        #expect(item.status == ClinicalOps.AdaptiveHandoffVarianceStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newAdaptiveHandoffVariance("code-115", label: "label-680")
        item.status = ClinicalOps.AdaptiveHandoffVarianceStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AdaptiveHandoffVarianceStatus.new) }
    }
}
