@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictShiftBundleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701226187)
        var items: [Staffing.StrictShiftBundle] = []
        for index in 0..<2 {
            items.append(Staffing.newStrictShiftBundle("strict-shift-bundle-\(index)", name: "sample"))
        }
        let report = Staffing.buildStrictShiftBundleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
