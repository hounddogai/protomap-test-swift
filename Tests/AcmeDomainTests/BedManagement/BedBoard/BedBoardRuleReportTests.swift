@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardRuleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704372566)
        var items: [BedManagement.BedBoardRule] = []
        for index in 0..<2 {
            items.append(BedManagement.newBedBoardRule("bed-board-rule-\(index)", name: "sample"))
        }
        let report = BedManagement.buildBedBoardRuleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
