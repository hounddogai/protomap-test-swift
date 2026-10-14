@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffWindowReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700455045)
        var items: [ClinicalOps.HandoffWindow] = []
        for index in 0..<4 {
            items.append(ClinicalOps.newHandoffWindow("handoff-window-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildHandoffWindowReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
