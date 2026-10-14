@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyReferenceRangeProfileReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705652979)
        var items: [Labs.LegacyReferenceRangeProfile] = []
        for index in 0..<2 {
            items.append(Labs.newLegacyReferenceRangeProfile("legacy-reference-range-profile-\(index)", label: "sample"))
        }
        let report = Labs.buildLegacyReferenceRangeProfileReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
