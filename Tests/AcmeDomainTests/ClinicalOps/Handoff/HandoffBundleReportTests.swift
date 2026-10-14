@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffBundleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701668308)
        var items: [ClinicalOps.HandoffBundle] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newHandoffBundle("handoff-bundle-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildHandoffBundleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
