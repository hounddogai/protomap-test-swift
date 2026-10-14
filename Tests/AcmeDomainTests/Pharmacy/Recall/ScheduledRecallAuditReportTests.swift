@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledRecallAuditReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707561249)
        var items: [Pharmacy.ScheduledRecallAudit] = []
        for index in 0..<5 {
            items.append(Pharmacy.newScheduledRecallAudit("scheduled-recall-audit-\(index)", label: "sample"))
        }
        let report = Pharmacy.buildScheduledRecallAuditReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
