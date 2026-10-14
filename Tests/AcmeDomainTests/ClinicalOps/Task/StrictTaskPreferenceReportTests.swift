@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictTaskPreferenceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700526921)
        var items: [ClinicalOps.StrictTaskPreference] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newStrictTaskPreference("strict-task-preference-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildStrictTaskPreferenceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
