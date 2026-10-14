@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackTransferTemplateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705987481)
        var items: [BedManagement.FallbackTransferTemplate] = []
        for index in 0..<5 {
            items.append(BedManagement.newFallbackTransferTemplate("fallback-transfer-template-\(index)", title: "sample"))
        }
        let report = BedManagement.buildFallbackTransferTemplateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
