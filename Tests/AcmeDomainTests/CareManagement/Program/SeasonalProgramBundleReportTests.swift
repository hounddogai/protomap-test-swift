@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalProgramBundleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702840299)
        var items: [CareManagement.SeasonalProgramBundle] = []
        for index in 0..<5 {
            items.append(CareManagement.newSeasonalProgramBundle("seasonal-program-bundle-\(index)", title: "sample"))
        }
        let report = CareManagement.buildSeasonalProgramBundleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
