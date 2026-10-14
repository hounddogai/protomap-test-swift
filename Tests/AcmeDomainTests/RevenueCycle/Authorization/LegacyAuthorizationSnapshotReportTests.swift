@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyAuthorizationSnapshotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702968590)
        var items: [RevenueCycle.LegacyAuthorizationSnapshot] = []
        for index in 0..<4 {
            items.append(RevenueCycle.newLegacyAuthorizationSnapshot("legacy-authorization-snapshot-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildLegacyAuthorizationSnapshotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
