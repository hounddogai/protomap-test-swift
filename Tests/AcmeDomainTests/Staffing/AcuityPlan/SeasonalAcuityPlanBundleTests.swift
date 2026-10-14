@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalAcuityPlanBundleTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newSeasonalAcuityPlanBundle("code-121", title: "title-473")
        #expect(item.status == Staffing.SeasonalAcuityPlanBundleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Staffing.newSeasonalAcuityPlanBundle("code-121", title: "title-473")
        try item.moveTo(Staffing.SeasonalAcuityPlanBundleStatus.draining)
        #expect(item.status == Staffing.SeasonalAcuityPlanBundleStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newSeasonalAcuityPlanBundle("code-121", title: "title-473")
        item.status = Staffing.SeasonalAcuityPlanBundleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SeasonalAcuityPlanBundleStatus.idle) }
    }
}
