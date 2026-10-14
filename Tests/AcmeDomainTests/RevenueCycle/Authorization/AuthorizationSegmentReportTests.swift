@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationSegmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700750886)
        var items: [RevenueCycle.AuthorizationSegment] = []
        for index in 0..<5 {
            items.append(RevenueCycle.newAuthorizationSegment("authorization-segment-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildAuthorizationSegmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
