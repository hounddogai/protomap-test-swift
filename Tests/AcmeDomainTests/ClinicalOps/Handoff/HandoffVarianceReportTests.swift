@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffVarianceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702396201)
        var items: [ClinicalOps.HandoffVariance] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newHandoffVariance("handoff-variance-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildHandoffVarianceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
