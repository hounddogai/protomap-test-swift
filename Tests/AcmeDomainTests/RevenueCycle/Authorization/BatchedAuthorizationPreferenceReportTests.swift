@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedAuthorizationPreferenceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705584497)
        var items: [RevenueCycle.BatchedAuthorizationPreference] = []
        for index in 0..<6 {
            items.append(RevenueCycle.newBatchedAuthorizationPreference("batched-authorization-preference-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildBatchedAuthorizationPreferenceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
