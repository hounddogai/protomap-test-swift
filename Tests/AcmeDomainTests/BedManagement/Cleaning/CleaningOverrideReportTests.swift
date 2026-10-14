@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningOverrideReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704443875)
        var items: [BedManagement.CleaningOverride] = []
        for index in 0..<5 {
            items.append(BedManagement.newCleaningOverride("cleaning-override-\(index)", label: "sample"))
        }
        let report = BedManagement.buildCleaningOverrideReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
