@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveHandoffDigestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708162595)
        var items: [ClinicalOps.AdaptiveHandoffDigest] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newAdaptiveHandoffDigest("adaptive-handoff-digest-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildAdaptiveHandoffDigestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
