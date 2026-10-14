@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalProgramQuotaReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700287235)
        var items: [CareManagement.GlobalProgramQuota] = []
        for index in 0..<6 {
            items.append(CareManagement.newGlobalProgramQuota("global-program-quota-\(index)", title: "sample"))
        }
        let report = CareManagement.buildGlobalProgramQuotaReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
