@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictAcuityPlanBundleTests {
    @Test func startsInNew() throws {
        let item = Staffing.newStrictAcuityPlanBundle("code-599", title: "title-451")
        #expect(item.status == Staffing.StrictAcuityPlanBundleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Staffing.newStrictAcuityPlanBundle("code-599", title: "title-451")
        try item.moveTo(Staffing.StrictAcuityPlanBundleStatus.running)
        #expect(item.status == Staffing.StrictAcuityPlanBundleStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newStrictAcuityPlanBundle("code-599", title: "title-451")
        item.status = Staffing.StrictAcuityPlanBundleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.StrictAcuityPlanBundleStatus.new) }
    }
}
