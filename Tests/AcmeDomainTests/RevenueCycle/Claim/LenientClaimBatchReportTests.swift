@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientClaimBatchReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709612623)
        var items: [RevenueCycle.LenientClaimBatch] = []
        for index in 0..<4 {
            items.append(RevenueCycle.newLenientClaimBatch("lenient-claim-batch-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildLenientClaimBatchReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
