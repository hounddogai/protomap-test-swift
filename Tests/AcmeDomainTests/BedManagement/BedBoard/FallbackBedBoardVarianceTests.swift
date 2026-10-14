@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackBedBoardVarianceTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newFallbackBedBoardVariance("code-547", name: "name-566")
        #expect(item.status == BedManagement.FallbackBedBoardVarianceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = BedManagement.newFallbackBedBoardVariance("code-547", name: "name-566")
        try item.moveTo(BedManagement.FallbackBedBoardVarianceStatus.rejected)
        #expect(item.status == BedManagement.FallbackBedBoardVarianceStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newFallbackBedBoardVariance("code-547", name: "name-566")
        item.status = BedManagement.FallbackBedBoardVarianceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.FallbackBedBoardVarianceStatus.proposed) }
    }
}
