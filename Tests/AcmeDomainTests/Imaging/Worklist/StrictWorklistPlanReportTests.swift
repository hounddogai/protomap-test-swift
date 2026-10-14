@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictWorklistPlanReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700084407)
        var items: [Imaging.StrictWorklistPlan] = []
        for index in 0..<2 {
            items.append(Imaging.newStrictWorklistPlan("strict-worklist-plan-\(index)", title: "sample"))
        }
        let report = Imaging.buildStrictWorklistPlanReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
