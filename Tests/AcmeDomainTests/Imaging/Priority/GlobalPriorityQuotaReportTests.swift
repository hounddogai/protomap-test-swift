@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalPriorityQuotaReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708515018)
        var items: [Imaging.GlobalPriorityQuota] = []
        for index in 0..<5 {
            items.append(Imaging.newGlobalPriorityQuota("global-priority-quota-\(index)", label: "sample"))
        }
        let report = Imaging.buildGlobalPriorityQuotaReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
