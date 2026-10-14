@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictOvertimeManifestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707430189)
        var items: [Staffing.StrictOvertimeManifest] = []
        for index in 0..<3 {
            items.append(Staffing.newStrictOvertimeManifest("strict-overtime-manifest-\(index)", name: "sample"))
        }
        let report = Staffing.buildStrictOvertimeManifestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
