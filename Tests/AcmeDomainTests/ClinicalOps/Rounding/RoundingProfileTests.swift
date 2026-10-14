@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingProfileTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newRoundingProfile("code-215", name: "name-475")
        #expect(item.status == ClinicalOps.RoundingProfileStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = ClinicalOps.newRoundingProfile("code-215", name: "name-475")
        try item.moveTo(ClinicalOps.RoundingProfileStatus.scheduled)
        #expect(item.status == ClinicalOps.RoundingProfileStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newRoundingProfile("code-215", name: "name-475")
        item.status = ClinicalOps.RoundingProfileStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingProfileStatus.planned) }
    }
}
