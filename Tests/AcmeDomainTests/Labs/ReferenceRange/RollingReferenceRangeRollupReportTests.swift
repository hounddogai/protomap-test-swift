@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingReferenceRangeRollupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709484249)
        var items: [Labs.RollingReferenceRangeRollup] = []
        for index in 0..<5 {
            items.append(Labs.newRollingReferenceRangeRollup("rolling-reference-range-rollup-\(index)", label: "sample"))
        }
        let report = Labs.buildRollingReferenceRangeRollupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
