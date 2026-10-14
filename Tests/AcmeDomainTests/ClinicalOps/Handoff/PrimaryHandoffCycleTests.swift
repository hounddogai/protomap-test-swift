@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryHandoffCycleTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newPrimaryHandoffCycle("code-108", label: "label-670")
        #expect(item.status == ClinicalOps.PrimaryHandoffCycleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = ClinicalOps.newPrimaryHandoffCycle("code-108", label: "label-670")
        try item.moveTo(ClinicalOps.PrimaryHandoffCycleStatus.warming)
        #expect(item.status == ClinicalOps.PrimaryHandoffCycleStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newPrimaryHandoffCycle("code-108", label: "label-670")
        item.status = ClinicalOps.PrimaryHandoffCycleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PrimaryHandoffCycleStatus.idle) }
    }
}
