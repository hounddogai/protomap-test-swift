@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictShiftBundleTests {
    @Test func startsInNew() throws {
        let item = Staffing.newStrictShiftBundle("code-541", name: "name-600")
        #expect(item.status == Staffing.StrictShiftBundleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Staffing.newStrictShiftBundle("code-541", name: "name-600")
        try item.moveTo(Staffing.StrictShiftBundleStatus.running)
        #expect(item.status == Staffing.StrictShiftBundleStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newStrictShiftBundle("code-541", name: "name-600")
        item.status = Staffing.StrictShiftBundleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.StrictShiftBundleStatus.new) }
    }
}
