@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalRoundingAllocationTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newSeasonalRoundingAllocation("code-455", title: "title-990")
        #expect(item.status == ClinicalOps.SeasonalRoundingAllocationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newSeasonalRoundingAllocation("code-455", title: "title-990")
        try item.moveTo(ClinicalOps.SeasonalRoundingAllocationStatus.granted)
        #expect(item.status == ClinicalOps.SeasonalRoundingAllocationStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newSeasonalRoundingAllocation("code-455", title: "title-990")
        item.status = ClinicalOps.SeasonalRoundingAllocationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.SeasonalRoundingAllocationStatus.requested) }
    }
}
