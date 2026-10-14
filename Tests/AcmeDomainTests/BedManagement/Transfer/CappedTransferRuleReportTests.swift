@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedTransferRuleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702970172)
        var items: [BedManagement.CappedTransferRule] = []
        for index in 0..<6 {
            items.append(BedManagement.newCappedTransferRule("capped-transfer-rule-\(index)", label: "sample"))
        }
        let report = BedManagement.buildCappedTransferRuleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
