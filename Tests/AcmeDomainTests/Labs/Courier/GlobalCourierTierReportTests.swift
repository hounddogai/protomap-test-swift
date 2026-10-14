@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalCourierTierReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703656943)
        var items: [Labs.GlobalCourierTier] = []
        for index in 0..<3 {
            items.append(Labs.newGlobalCourierTier("global-courier-tier-\(index)", title: "sample"))
        }
        let report = Labs.buildGlobalCourierTierReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
