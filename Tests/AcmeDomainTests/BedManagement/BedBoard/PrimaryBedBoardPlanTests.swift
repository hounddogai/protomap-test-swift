@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryBedBoardPlanTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newPrimaryBedBoardPlan("code-628", name: "name-689")
        #expect(item.status == BedManagement.PrimaryBedBoardPlanStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = BedManagement.newPrimaryBedBoardPlan("code-628", name: "name-689")
        try item.moveTo(BedManagement.PrimaryBedBoardPlanStatus.withdrawn)
        #expect(item.status == BedManagement.PrimaryBedBoardPlanStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newPrimaryBedBoardPlan("code-628", name: "name-689")
        item.status = BedManagement.PrimaryBedBoardPlanStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PrimaryBedBoardPlanStatus.proposed) }
    }
}
