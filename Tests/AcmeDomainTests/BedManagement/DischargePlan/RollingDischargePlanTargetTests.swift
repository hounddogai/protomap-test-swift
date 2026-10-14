@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingDischargePlanTargetTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newRollingDischargePlanTarget("code-21", title: "title-899")
        #expect(item.status == BedManagement.RollingDischargePlanTargetStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = BedManagement.newRollingDischargePlanTarget("code-21", title: "title-899")
        try item.moveTo(BedManagement.RollingDischargePlanTargetStatus.done)
        #expect(item.status == BedManagement.RollingDischargePlanTargetStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newRollingDischargePlanTarget("code-21", title: "title-899")
        item.status = BedManagement.RollingDischargePlanTargetStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.RollingDischargePlanTargetStatus.new) }
    }
}
