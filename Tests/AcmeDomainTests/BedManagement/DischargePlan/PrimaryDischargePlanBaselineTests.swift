@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryDischargePlanBaselineTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newPrimaryDischargePlanBaseline("code-163", title: "title-663")
        #expect(item.status == BedManagement.PrimaryDischargePlanBaselineStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = BedManagement.newPrimaryDischargePlanBaseline("code-163", title: "title-663")
        try item.moveTo(BedManagement.PrimaryDischargePlanBaselineStatus.approved)
        #expect(item.status == BedManagement.PrimaryDischargePlanBaselineStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newPrimaryDischargePlanBaseline("code-163", title: "title-663")
        item.status = BedManagement.PrimaryDischargePlanBaselineStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PrimaryDischargePlanBaselineStatus.proposed) }
    }
}
