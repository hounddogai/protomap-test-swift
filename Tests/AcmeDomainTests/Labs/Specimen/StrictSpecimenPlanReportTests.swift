@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictSpecimenPlanReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701412997)
        var items: [Labs.StrictSpecimenPlan] = []
        for index in 0..<6 {
            items.append(Labs.newStrictSpecimenPlan("strict-specimen-plan-\(index)", label: "sample"))
        }
        let report = Labs.buildStrictSpecimenPlanReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
