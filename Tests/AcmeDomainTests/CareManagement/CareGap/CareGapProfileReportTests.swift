@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapProfileReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709977096)
        var items: [CareManagement.CareGapProfile] = []
        for index in 0..<5 {
            items.append(CareManagement.newCareGapProfile("care-gap-profile-\(index)", name: "sample"))
        }
        let report = CareManagement.buildCareGapProfileReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
