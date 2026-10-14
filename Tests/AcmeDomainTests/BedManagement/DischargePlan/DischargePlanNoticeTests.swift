@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanNoticeTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newDischargePlanNotice("code-9", name: "name-933")
        #expect(item.status == BedManagement.DischargePlanNoticeStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = BedManagement.newDischargePlanNotice("code-9", name: "name-933")
        try item.moveTo(BedManagement.DischargePlanNoticeStatus.rejected)
        #expect(item.status == BedManagement.DischargePlanNoticeStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newDischargePlanNotice("code-9", name: "name-933")
        item.status = BedManagement.DischargePlanNoticeStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanNoticeStatus.proposed) }
    }
}
