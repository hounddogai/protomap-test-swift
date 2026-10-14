@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanCheckpointReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702389094)
        var items: [Staffing.AcuityPlanCheckpoint] = []
        for index in 0..<2 {
            items.append(Staffing.newAcuityPlanCheckpoint("acuity-plan-checkpoint-\(index)", name: "sample"))
        }
        let report = Staffing.buildAcuityPlanCheckpointReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
