@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualShiftScoreReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701998241)
        var items: [Staffing.ManualShiftScore] = []
        for index in 0..<6 {
            items.append(Staffing.newManualShiftScore("manual-shift-score-\(index)", name: "sample"))
        }
        let report = Staffing.buildManualShiftScoreReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
