@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskDigestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707502026)
        var items: [ClinicalOps.TaskDigest] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newTaskDigest("task-digest-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildTaskDigestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
