@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalShiftMetricTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newSeasonalShiftMetric("code-445", name: "name-260")
        #expect(item.status == Staffing.SeasonalShiftMetricStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Staffing.newSeasonalShiftMetric("code-445", name: "name-260")
        try item.moveTo(Staffing.SeasonalShiftMetricStatus.warming)
        #expect(item.status == Staffing.SeasonalShiftMetricStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newSeasonalShiftMetric("code-445", name: "name-260")
        item.status = Staffing.SeasonalShiftMetricStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SeasonalShiftMetricStatus.idle) }
    }
}
