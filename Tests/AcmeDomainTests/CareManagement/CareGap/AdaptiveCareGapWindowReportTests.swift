@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveCareGapWindowReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702424505)
        var items: [CareManagement.AdaptiveCareGapWindow] = []
        for index in 0..<6 {
            items.append(CareManagement.newAdaptiveCareGapWindow("adaptive-care-gap-window-\(index)", title: "sample"))
        }
        let report = CareManagement.buildAdaptiveCareGapWindowReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
