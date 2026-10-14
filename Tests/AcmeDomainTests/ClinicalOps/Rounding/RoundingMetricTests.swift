@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingMetricTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newRoundingMetric("code-143", name: "name-762")
        #expect(item.status == ClinicalOps.RoundingMetricStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = ClinicalOps.newRoundingMetric("code-143", name: "name-762")
        try item.moveTo(ClinicalOps.RoundingMetricStatus.resolved)
        #expect(item.status == ClinicalOps.RoundingMetricStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newRoundingMetric("code-143", name: "name-762")
        item.status = ClinicalOps.RoundingMetricStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingMetricStatus.`open`) }
    }
}
