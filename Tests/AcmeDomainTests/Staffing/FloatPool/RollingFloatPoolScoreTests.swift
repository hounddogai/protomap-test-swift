@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingFloatPoolScoreTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newRollingFloatPoolScore("code-842", label: "label-889")
        #expect(item.status == Staffing.RollingFloatPoolScoreStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Staffing.newRollingFloatPoolScore("code-842", label: "label-889")
        try item.moveTo(Staffing.RollingFloatPoolScoreStatus.expired)
        #expect(item.status == Staffing.RollingFloatPoolScoreStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newRollingFloatPoolScore("code-842", label: "label-889")
        item.status = Staffing.RollingFloatPoolScoreStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.RollingFloatPoolScoreStatus.requested) }
    }
}
