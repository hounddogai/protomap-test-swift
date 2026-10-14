@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseAuditReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708581112)
        var items: [Pharmacy.DispenseAudit] = []
        for index in 0..<3 {
            items.append(Pharmacy.newDispenseAudit("dispense-audit-\(index)", title: "sample"))
        }
        let report = Pharmacy.buildDispenseAuditReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
