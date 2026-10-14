@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanRequestTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newDischargePlanRequest("code-549", name: "name-587")
        #expect(item.status == BedManagement.DischargePlanRequestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = BedManagement.newDischargePlanRequest("code-549", name: "name-587")
        try item.moveTo(BedManagement.DischargePlanRequestStatus.approved)
        #expect(item.status == BedManagement.DischargePlanRequestStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newDischargePlanRequest("code-549", name: "name-587")
        item.status = BedManagement.DischargePlanRequestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanRequestStatus.proposed) }
    }
}
