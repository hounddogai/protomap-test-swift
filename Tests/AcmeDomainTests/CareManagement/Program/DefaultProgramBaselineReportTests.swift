@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultProgramBaselineReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706153137)
        var items: [CareManagement.DefaultProgramBaseline] = []
        for index in 0..<5 {
            items.append(CareManagement.newDefaultProgramBaseline("default-program-baseline-\(index)", label: "sample"))
        }
        let report = CareManagement.buildDefaultProgramBaselineReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
