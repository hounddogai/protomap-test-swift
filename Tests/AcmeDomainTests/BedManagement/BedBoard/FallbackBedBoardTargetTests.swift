@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackBedBoardTargetTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newFallbackBedBoardTarget("code-81", label: "label-354")
        #expect(item.status == BedManagement.FallbackBedBoardTargetStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = BedManagement.newFallbackBedBoardTarget("code-81", label: "label-354")
        try item.moveTo(BedManagement.FallbackBedBoardTargetStatus.rejected)
        #expect(item.status == BedManagement.FallbackBedBoardTargetStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newFallbackBedBoardTarget("code-81", label: "label-354")
        item.status = BedManagement.FallbackBedBoardTargetStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.FallbackBedBoardTargetStatus.proposed) }
    }
}
