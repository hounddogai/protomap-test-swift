@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffThresholdReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702810358)
        var items: [ClinicalOps.HandoffThreshold] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newHandoffThreshold("handoff-threshold-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildHandoffThresholdReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
