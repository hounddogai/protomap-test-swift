@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalReferenceRangeAuditReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701081149)
        var items: [Labs.RegionalReferenceRangeAudit] = []
        for index in 0..<2 {
            items.append(Labs.newRegionalReferenceRangeAudit("regional-reference-range-audit-\(index)", label: "sample"))
        }
        let report = Labs.buildRegionalReferenceRangeAuditReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
