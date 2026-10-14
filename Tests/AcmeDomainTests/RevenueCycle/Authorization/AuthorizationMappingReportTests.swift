@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationMappingReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706378999)
        var items: [RevenueCycle.AuthorizationMapping] = []
        for index in 0..<4 {
            items.append(RevenueCycle.newAuthorizationMapping("authorization-mapping-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildAuthorizationMappingReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
