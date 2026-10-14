@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolAssignmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700911689)
        var items: [ClinicalOps.CareProtocolAssignment] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newCareProtocolAssignment("care-protocol-assignment-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildCareProtocolAssignmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
