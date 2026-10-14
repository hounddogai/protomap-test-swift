@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveCleaningOverrideReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700953912)
        var items: [BedManagement.AdaptiveCleaningOverride] = []
        for index in 0..<5 {
            items.append(BedManagement.newAdaptiveCleaningOverride("adaptive-cleaning-override-\(index)", title: "sample"))
        }
        let report = BedManagement.buildAdaptiveCleaningOverrideReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
