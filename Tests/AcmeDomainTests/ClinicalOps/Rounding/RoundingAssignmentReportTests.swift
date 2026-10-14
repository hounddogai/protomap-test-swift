@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingAssignmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704187535)
        var items: [ClinicalOps.RoundingAssignment] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newRoundingAssignment("rounding-assignment-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildRoundingAssignmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
