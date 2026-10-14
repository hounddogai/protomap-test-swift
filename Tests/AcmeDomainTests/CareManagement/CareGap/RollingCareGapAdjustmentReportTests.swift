@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingCareGapAdjustmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703887926)
        var items: [CareManagement.RollingCareGapAdjustment] = []
        for index in 0..<5 {
            items.append(CareManagement.newRollingCareGapAdjustment("rolling-care-gap-adjustment-\(index)", label: "sample"))
        }
        let report = CareManagement.buildRollingCareGapAdjustmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
