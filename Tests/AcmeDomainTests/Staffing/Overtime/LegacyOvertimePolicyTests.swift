@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyOvertimePolicyTests {
    @Test func startsInNew() throws {
        let item = Staffing.newLegacyOvertimePolicy("code-239", name: "name-310")
        #expect(item.status == Staffing.LegacyOvertimePolicyStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Staffing.newLegacyOvertimePolicy("code-239", name: "name-310")
        try item.moveTo(Staffing.LegacyOvertimePolicyStatus.failed)
        #expect(item.status == Staffing.LegacyOvertimePolicyStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newLegacyOvertimePolicy("code-239", name: "name-310")
        item.status = Staffing.LegacyOvertimePolicyStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LegacyOvertimePolicyStatus.new) }
    }
}
