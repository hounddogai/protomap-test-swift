@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningRecordReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703540060)
        var items: [BedManagement.CleaningRecord] = []
        for index in 0..<2 {
            items.append(BedManagement.newCleaningRecord("cleaning-record-\(index)", name: "sample"))
        }
        let report = BedManagement.buildCleaningRecordReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
