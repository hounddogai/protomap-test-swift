@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanRollupTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newDischargePlanRollup("code-141", title: "title-105")
        #expect(item.status == BedManagement.DischargePlanRollupStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = BedManagement.newDischargePlanRollup("code-141", title: "title-105")
        try item.moveTo(BedManagement.DischargePlanRollupStatus.published)
        #expect(item.status == BedManagement.DischargePlanRollupStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newDischargePlanRollup("code-141", title: "title-105")
        item.status = BedManagement.DischargePlanRollupStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanRollupStatus.created) }
    }
}
