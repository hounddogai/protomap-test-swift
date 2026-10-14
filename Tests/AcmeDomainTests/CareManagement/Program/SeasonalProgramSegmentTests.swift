@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalProgramSegmentTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newSeasonalProgramSegment("code-568", label: "label-266")
        #expect(item.status == CareManagement.SeasonalProgramSegmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = CareManagement.newSeasonalProgramSegment("code-568", label: "label-266")
        try item.moveTo(CareManagement.SeasonalProgramSegmentStatus.rejected)
        #expect(item.status == CareManagement.SeasonalProgramSegmentStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newSeasonalProgramSegment("code-568", label: "label-266")
        item.status = CareManagement.SeasonalProgramSegmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.SeasonalProgramSegmentStatus.proposed) }
    }
}
