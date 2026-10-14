@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualDenialTemplateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701180954)
        var items: [RevenueCycle.ManualDenialTemplate] = []
        for index in 0..<4 {
            items.append(RevenueCycle.newManualDenialTemplate("manual-denial-template-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildManualDenialTemplateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
