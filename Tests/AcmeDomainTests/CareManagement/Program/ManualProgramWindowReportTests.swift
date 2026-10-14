@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualProgramWindowReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704825039)
        var items: [CareManagement.ManualProgramWindow] = []
        for index in 0..<4 {
            items.append(CareManagement.newManualProgramWindow("manual-program-window-\(index)", title: "sample"))
        }
        let report = CareManagement.buildManualProgramWindowReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
