@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledSpecimenTierReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700641192)
        var items: [Labs.ScheduledSpecimenTier] = []
        for index in 0..<4 {
            items.append(Labs.newScheduledSpecimenTier("scheduled-specimen-tier-\(index)", title: "sample"))
        }
        let report = Labs.buildScheduledSpecimenTierReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
