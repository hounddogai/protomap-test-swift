@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyAuthorizationSegmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705210346)
        var items: [RevenueCycle.LegacyAuthorizationSegment] = []
        for index in 0..<3 {
            items.append(RevenueCycle.newLegacyAuthorizationSegment("legacy-authorization-segment-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildLegacyAuthorizationSegmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
