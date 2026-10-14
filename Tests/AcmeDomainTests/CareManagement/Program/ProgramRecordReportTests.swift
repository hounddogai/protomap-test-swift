@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramRecordReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703091371)
        var items: [CareManagement.ProgramRecord] = []
        for index in 0..<3 {
            items.append(CareManagement.newProgramRecord("program-record-\(index)", label: "sample"))
        }
        let report = CareManagement.buildProgramRecordReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
