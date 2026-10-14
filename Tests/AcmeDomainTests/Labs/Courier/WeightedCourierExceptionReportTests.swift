@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedCourierExceptionReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704563476)
        var items: [Labs.WeightedCourierException] = []
        for index in 0..<2 {
            items.append(Labs.newWeightedCourierException("weighted-courier-exception-\(index)", label: "sample"))
        }
        let report = Labs.buildWeightedCourierExceptionReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
