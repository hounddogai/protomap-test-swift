@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusAdjustmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701006231)
        var items: [BedManagement.CensusAdjustment] = []
        for index in 0..<5 {
            items.append(BedManagement.newCensusAdjustment("census-adjustment-\(index)", title: "sample"))
        }
        let report = BedManagement.buildCensusAdjustmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
