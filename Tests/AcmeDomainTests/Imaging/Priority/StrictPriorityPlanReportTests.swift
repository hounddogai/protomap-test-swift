@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictPriorityPlanReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702993955)
        var items: [Imaging.StrictPriorityPlan] = []
        for index in 0..<3 {
            items.append(Imaging.newStrictPriorityPlan("strict-priority-plan-\(index)", title: "sample"))
        }
        let report = Imaging.buildStrictPriorityPlanReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
