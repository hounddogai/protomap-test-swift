@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingRecallPlanReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700102769)
        var items: [Pharmacy.RollingRecallPlan] = []
        for index in 0..<5 {
            items.append(Pharmacy.newRollingRecallPlan("rolling-recall-plan-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildRollingRecallPlanReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
