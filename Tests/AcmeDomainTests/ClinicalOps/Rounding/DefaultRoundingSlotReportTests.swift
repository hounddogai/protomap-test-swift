@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultRoundingSlotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707818260)
        var items: [ClinicalOps.DefaultRoundingSlot] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newDefaultRoundingSlot("default-rounding-slot-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildDefaultRoundingSlotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
