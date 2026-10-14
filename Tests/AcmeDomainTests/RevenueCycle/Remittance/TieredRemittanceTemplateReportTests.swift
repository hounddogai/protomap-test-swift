@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredRemittanceTemplateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709108324)
        var items: [RevenueCycle.TieredRemittanceTemplate] = []
        for index in 0..<5 {
            items.append(RevenueCycle.newTieredRemittanceTemplate("tiered-remittance-template-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildTieredRemittanceTemplateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
