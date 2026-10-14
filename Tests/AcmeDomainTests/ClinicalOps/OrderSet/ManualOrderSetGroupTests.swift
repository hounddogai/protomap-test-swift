@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsManualOrderSetGroupTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newManualOrderSetGroup("code-180", name: "name-759")
        #expect(item.status == ClinicalOps.ManualOrderSetGroupStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = ClinicalOps.newManualOrderSetGroup("code-180", name: "name-759")
        try item.moveTo(ClinicalOps.ManualOrderSetGroupStatus.inProgress)
        #expect(item.status == ClinicalOps.ManualOrderSetGroupStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newManualOrderSetGroup("code-180", name: "name-759")
        item.status = ClinicalOps.ManualOrderSetGroupStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.ManualOrderSetGroupStatus.planned) }
    }
}
