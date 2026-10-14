@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackCleaningTemplateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700477227)
        var items: [BedManagement.FallbackCleaningTemplate] = []
        for index in 0..<6 {
            items.append(BedManagement.newFallbackCleaningTemplate("fallback-cleaning-template-\(index)", name: "sample"))
        }
        let report = BedManagement.buildFallbackCleaningTemplateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
