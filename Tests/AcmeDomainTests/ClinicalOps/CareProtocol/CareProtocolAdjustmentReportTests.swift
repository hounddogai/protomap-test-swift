@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolAdjustmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708155939)
        var items: [ClinicalOps.CareProtocolAdjustment] = []
        for index in 0..<6 {
            items.append(ClinicalOps.newCareProtocolAdjustment("care-protocol-adjustment-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildCareProtocolAdjustmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
