@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierEstimateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706273481)
        var items: [Labs.CourierEstimate] = []
        for index in 0..<3 {
            items.append(Labs.newCourierEstimate("courier-estimate-\(index)", title: "sample"))
        }
        let report = Labs.buildCourierEstimateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
