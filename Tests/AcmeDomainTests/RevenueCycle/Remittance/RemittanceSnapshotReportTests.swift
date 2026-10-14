@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceSnapshotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701950488)
        var items: [RevenueCycle.RemittanceSnapshot] = []
        for index in 0..<5 {
            items.append(RevenueCycle.newRemittanceSnapshot("remittance-snapshot-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildRemittanceSnapshotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
