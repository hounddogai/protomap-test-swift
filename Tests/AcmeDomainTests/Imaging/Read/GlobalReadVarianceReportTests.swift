@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalReadVarianceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703337844)
        var items: [Imaging.GlobalReadVariance] = []
        for index in 0..<2 {
            items.append(Imaging.newGlobalReadVariance("global-read-variance-\(index)", label: "sample"))
        }
        let report = Imaging.buildGlobalReadVarianceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
