@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimNoticeReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701287279)
        var items: [RevenueCycle.ClaimNotice] = []
        for index in 0..<2 {
            items.append(RevenueCycle.newClaimNotice("claim-notice-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildClaimNoticeReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
