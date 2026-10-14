@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredOrderSetCycleTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newTieredOrderSetCycle("code-304", label: "label-66")
        #expect(item.status == ClinicalOps.TieredOrderSetCycleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = ClinicalOps.newTieredOrderSetCycle("code-304", label: "label-66")
        try item.moveTo(ClinicalOps.TieredOrderSetCycleStatus.completed)
        #expect(item.status == ClinicalOps.TieredOrderSetCycleStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newTieredOrderSetCycle("code-304", label: "label-66")
        item.status = ClinicalOps.TieredOrderSetCycleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TieredOrderSetCycleStatus.planned) }
    }
}
