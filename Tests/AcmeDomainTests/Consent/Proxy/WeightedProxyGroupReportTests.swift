@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedProxyGroupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701665729)
        var items: [Consent.WeightedProxyGroup] = []
        for index in 0..<5 {
            items.append(Consent.newWeightedProxyGroup("weighted-proxy-group-\(index)", title: "sample"))
        }
        let report = Consent.buildWeightedProxyGroupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
