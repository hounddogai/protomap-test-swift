@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingGroupTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newRoundingGroup("code-60", name: "name-55")
        #expect(item.status == ClinicalOps.RoundingGroupStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = ClinicalOps.newRoundingGroup("code-60", name: "name-55")
        try item.moveTo(ClinicalOps.RoundingGroupStatus.scheduled)
        #expect(item.status == ClinicalOps.RoundingGroupStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newRoundingGroup("code-60", name: "name-55")
        item.status = ClinicalOps.RoundingGroupStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingGroupStatus.planned) }
    }
}
