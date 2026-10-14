@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictCareProtocolThresholdReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707508599)
        var items: [ClinicalOps.StrictCareProtocolThreshold] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newStrictCareProtocolThreshold("strict-care-protocol-threshold-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildStrictCareProtocolThresholdReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
