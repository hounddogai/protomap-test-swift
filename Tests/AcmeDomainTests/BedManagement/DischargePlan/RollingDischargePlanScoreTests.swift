@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingDischargePlanScoreTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newRollingDischargePlanScore("code-451", title: "title-363")
        #expect(item.status == BedManagement.RollingDischargePlanScoreStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = BedManagement.newRollingDischargePlanScore("code-451", title: "title-363")
        try item.moveTo(BedManagement.RollingDischargePlanScoreStatus.granted)
        #expect(item.status == BedManagement.RollingDischargePlanScoreStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newRollingDischargePlanScore("code-451", title: "title-363")
        item.status = BedManagement.RollingDischargePlanScoreStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.RollingDischargePlanScoreStatus.requested) }
    }
}
