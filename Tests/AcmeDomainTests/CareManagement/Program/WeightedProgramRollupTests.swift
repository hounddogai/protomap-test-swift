@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedProgramRollupTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newWeightedProgramRollup("code-216", label: "label-839")
        #expect(item.status == CareManagement.WeightedProgramRollupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = CareManagement.newWeightedProgramRollup("code-216", label: "label-839")
        try item.moveTo(CareManagement.WeightedProgramRollupStatus.running)
        #expect(item.status == CareManagement.WeightedProgramRollupStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newWeightedProgramRollup("code-216", label: "label-839")
        item.status = CareManagement.WeightedProgramRollupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.WeightedProgramRollupStatus.new) }
    }
}
