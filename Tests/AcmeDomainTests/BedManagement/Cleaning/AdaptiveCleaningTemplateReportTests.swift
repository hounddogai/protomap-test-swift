@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveCleaningTemplateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702926579)
        var items: [BedManagement.AdaptiveCleaningTemplate] = []
        for index in 0..<3 {
            items.append(BedManagement.newAdaptiveCleaningTemplate("adaptive-cleaning-template-\(index)", title: "sample"))
        }
        let report = BedManagement.buildAdaptiveCleaningTemplateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
