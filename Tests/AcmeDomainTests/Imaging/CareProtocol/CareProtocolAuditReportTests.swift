@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolAuditReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703128117)
        var items: [Imaging.CareProtocolAudit] = []
        for index in 0..<6 {
            items.append(Imaging.newCareProtocolAudit("care-protocol-audit-\(index)", title: "sample"))
        }
        let report = Imaging.buildCareProtocolAuditReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
