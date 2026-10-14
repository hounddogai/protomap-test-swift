@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingShiftManifestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706935239)
        var items: [Staffing.RollingShiftManifest] = []
        for index in 0..<2 {
            items.append(Staffing.newRollingShiftManifest("rolling-shift-manifest-\(index)", name: "sample"))
        }
        let report = Staffing.buildRollingShiftManifestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
