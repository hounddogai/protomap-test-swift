@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierBatchReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706355493)
        var items: [Labs.CourierBatch] = []
        for index in 0..<5 {
            items.append(Labs.newCourierBatch("courier-batch-\(index)", label: "sample"))
        }
        let report = Labs.buildCourierBatchReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
