@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalOrderSetEstimateTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newGlobalOrderSetEstimate("code-6", title: "title-500")
        #expect(item.status == ClinicalOps.GlobalOrderSetEstimateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = ClinicalOps.newGlobalOrderSetEstimate("code-6", title: "title-500")
        try item.moveTo(ClinicalOps.GlobalOrderSetEstimateStatus.done)
        #expect(item.status == ClinicalOps.GlobalOrderSetEstimateStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newGlobalOrderSetEstimate("code-6", title: "title-500")
        item.status = ClinicalOps.GlobalOrderSetEstimateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.GlobalOrderSetEstimateStatus.new) }
    }
}
