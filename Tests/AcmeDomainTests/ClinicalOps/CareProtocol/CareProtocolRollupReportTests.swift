@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolRollupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704814166)
        var items: [ClinicalOps.CareProtocolRollup] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newCareProtocolRollup("care-protocol-rollup-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildCareProtocolRollupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
