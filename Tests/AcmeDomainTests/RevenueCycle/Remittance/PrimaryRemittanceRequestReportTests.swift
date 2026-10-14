@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePrimaryRemittanceRequestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705176829)
        var items: [RevenueCycle.PrimaryRemittanceRequest] = []
        for index in 0..<2 {
            items.append(RevenueCycle.newPrimaryRemittanceRequest("primary-remittance-request-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildPrimaryRemittanceRequestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
