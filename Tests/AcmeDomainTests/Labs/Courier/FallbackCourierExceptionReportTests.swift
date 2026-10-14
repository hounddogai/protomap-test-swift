@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackCourierExceptionReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700503005)
        var items: [Labs.FallbackCourierException] = []
        for index in 0..<2 {
            items.append(Labs.newFallbackCourierException("fallback-courier-exception-\(index)", title: "sample"))
        }
        let report = Labs.buildFallbackCourierExceptionReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
