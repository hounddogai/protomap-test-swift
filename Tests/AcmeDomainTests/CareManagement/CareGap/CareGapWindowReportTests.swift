@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapWindowReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705729334)
        var items: [CareManagement.CareGapWindow] = []
        for index in 0..<5 {
            items.append(CareManagement.newCareGapWindow("care-gap-window-\(index)", name: "sample"))
        }
        let report = CareManagement.buildCareGapWindowReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
