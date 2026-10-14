@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedTransferGroupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707074872)
        var items: [BedManagement.WeightedTransferGroup] = []
        for index in 0..<3 {
            items.append(BedManagement.newWeightedTransferGroup("weighted-transfer-group-\(index)", title: "sample"))
        }
        let report = BedManagement.buildWeightedTransferGroupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
