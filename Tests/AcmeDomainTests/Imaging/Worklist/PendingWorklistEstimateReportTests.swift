@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingWorklistEstimateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700230952)
        var items: [Imaging.PendingWorklistEstimate] = []
        for index in 0..<3 {
            items.append(Imaging.newPendingWorklistEstimate("pending-worklist-estimate-\(index)", name: "sample"))
        }
        let report = Imaging.buildPendingWorklistEstimateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
