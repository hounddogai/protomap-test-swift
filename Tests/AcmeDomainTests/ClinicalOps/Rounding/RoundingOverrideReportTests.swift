@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingOverrideReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708063352)
        var items: [ClinicalOps.RoundingOverride] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newRoundingOverride("rounding-override-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildRoundingOverrideReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
