@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertSegmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701699525)
        var items: [ClinicalOps.AlertSegment] = []
        for index in 0..<5 {
            items.append(ClinicalOps.newAlertSegment("alert-segment-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildAlertSegmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
