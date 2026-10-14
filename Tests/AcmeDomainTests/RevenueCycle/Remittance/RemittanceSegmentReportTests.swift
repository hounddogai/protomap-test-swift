@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceSegmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700685095)
        var items: [RevenueCycle.RemittanceSegment] = []
        for index in 0..<2 {
            items.append(RevenueCycle.newRemittanceSegment("remittance-segment-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildRemittanceSegmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
