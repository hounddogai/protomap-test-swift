@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedAuthorizationRequestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706482536)
        var items: [RevenueCycle.WeightedAuthorizationRequest] = []
        for index in 0..<2 {
            items.append(RevenueCycle.newWeightedAuthorizationRequest("weighted-authorization-request-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildWeightedAuthorizationRequestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
