@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalOrderSetRollupTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newRegionalOrderSetRollup("code-4", name: "name-839")
        #expect(item.status == ClinicalOps.RegionalOrderSetRollupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = ClinicalOps.newRegionalOrderSetRollup("code-4", name: "name-839")
        try item.moveTo(ClinicalOps.RegionalOrderSetRollupStatus.queued)
        #expect(item.status == ClinicalOps.RegionalOrderSetRollupStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newRegionalOrderSetRollup("code-4", name: "name-839")
        item.status = ClinicalOps.RegionalOrderSetRollupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RegionalOrderSetRollupStatus.new) }
    }
}
