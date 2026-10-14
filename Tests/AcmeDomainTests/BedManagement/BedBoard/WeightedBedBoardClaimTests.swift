@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedBedBoardClaimTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newWeightedBedBoardClaim("code-163", name: "name-900")
        #expect(item.status == BedManagement.WeightedBedBoardClaimStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = BedManagement.newWeightedBedBoardClaim("code-163", name: "name-900")
        try item.moveTo(BedManagement.WeightedBedBoardClaimStatus.rejected)
        #expect(item.status == BedManagement.WeightedBedBoardClaimStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newWeightedBedBoardClaim("code-163", name: "name-900")
        item.status = BedManagement.WeightedBedBoardClaimStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.WeightedBedBoardClaimStatus.proposed) }
    }
}
