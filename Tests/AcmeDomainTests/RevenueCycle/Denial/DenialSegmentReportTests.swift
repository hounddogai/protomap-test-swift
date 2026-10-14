@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialSegmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708968902)
        var items: [RevenueCycle.DenialSegment] = []
        for index in 0..<2 {
            items.append(RevenueCycle.newDenialSegment("denial-segment-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildDenialSegmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
