@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalHandoffPolicyTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newSeasonalHandoffPolicy("code-749", name: "name-851")
        #expect(item.status == ClinicalOps.SeasonalHandoffPolicyStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = ClinicalOps.newSeasonalHandoffPolicy("code-749", name: "name-851")
        try item.moveTo(ClinicalOps.SeasonalHandoffPolicyStatus.cancelled)
        #expect(item.status == ClinicalOps.SeasonalHandoffPolicyStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newSeasonalHandoffPolicy("code-749", name: "name-851")
        item.status = ClinicalOps.SeasonalHandoffPolicyStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.SeasonalHandoffPolicyStatus.planned) }
    }
}
