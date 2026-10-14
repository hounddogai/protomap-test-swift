@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalOrderSetAssignmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704102365)
        var items: [ClinicalOps.GlobalOrderSetAssignment] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newGlobalOrderSetAssignment("global-order-set-assignment-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildGlobalOrderSetAssignmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
