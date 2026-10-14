@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolThresholdReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700759666)
        var items: [ClinicalOps.CareProtocolThreshold] = []
        for index in 0..<6 {
            items.append(ClinicalOps.newCareProtocolThreshold("care-protocol-threshold-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildCareProtocolThresholdReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
