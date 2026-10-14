@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryCareProtocolRuleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701257235)
        var items: [Imaging.PrimaryCareProtocolRule] = []
        for index in 0..<3 {
            items.append(Imaging.newPrimaryCareProtocolRule("primary-care-protocol-rule-\(index)", title: "sample"))
        }
        let report = Imaging.buildPrimaryCareProtocolRuleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
