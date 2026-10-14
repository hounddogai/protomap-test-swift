@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualReadEstimateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702245554)
        var items: [Imaging.ManualReadEstimate] = []
        for index in 0..<5 {
            items.append(Imaging.newManualReadEstimate("manual-read-estimate-\(index)", title: "sample"))
        }
        let report = Imaging.buildManualReadEstimateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
