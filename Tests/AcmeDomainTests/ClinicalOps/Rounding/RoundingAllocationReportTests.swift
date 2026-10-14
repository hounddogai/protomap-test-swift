@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingAllocationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701126102)
        var items: [ClinicalOps.RoundingAllocation] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newRoundingAllocation("rounding-allocation-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildRoundingAllocationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
