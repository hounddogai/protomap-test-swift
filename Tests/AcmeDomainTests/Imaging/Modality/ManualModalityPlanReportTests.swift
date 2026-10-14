@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualModalityPlanReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701002832)
        var items: [Imaging.ManualModalityPlan] = []
        for index in 0..<2 {
            items.append(Imaging.newManualModalityPlan("manual-modality-plan-\(index)", title: "sample"))
        }
        let report = Imaging.buildManualModalityPlanReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
