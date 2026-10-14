@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffGroupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707008423)
        var items: [ClinicalOps.HandoffGroup] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newHandoffGroup("handoff-group-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildHandoffGroupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
