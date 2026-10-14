@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeBundleTests {
    @Test func startsInNew() throws {
        let item = Staffing.newOvertimeBundle("code-168", title: "title-603")
        #expect(item.status == Staffing.OvertimeBundleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Staffing.newOvertimeBundle("code-168", title: "title-603")
        try item.moveTo(Staffing.OvertimeBundleStatus.running)
        #expect(item.status == Staffing.OvertimeBundleStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newOvertimeBundle("code-168", title: "title-603")
        item.status = Staffing.OvertimeBundleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeBundleStatus.new) }
    }
}
