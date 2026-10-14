@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeAgreementReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706796009)
        var items: [RevenueCycle.ChargeAgreement] = []
        for index in 0..<2 {
            items.append(RevenueCycle.newChargeAgreement("charge-agreement-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildChargeAgreementReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
