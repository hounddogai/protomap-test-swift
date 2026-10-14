@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingCleaningSlotTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newRollingCleaningSlot("code-417", title: "title-807")
        #expect(item.status == BedManagement.RollingCleaningSlotStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = BedManagement.newRollingCleaningSlot("code-417", title: "title-807")
        try item.moveTo(BedManagement.RollingCleaningSlotStatus.approved)
        #expect(item.status == BedManagement.RollingCleaningSlotStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newRollingCleaningSlot("code-417", title: "title-807")
        item.status = BedManagement.RollingCleaningSlotStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.RollingCleaningSlotStatus.proposed) }
    }
}
