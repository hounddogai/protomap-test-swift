@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictCareProtocolRecordReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703613400)
        var items: [ClinicalOps.StrictCareProtocolRecord] = []
        for index in 0..<5 {
            items.append(ClinicalOps.newStrictCareProtocolRecord("strict-care-protocol-record-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildStrictCareProtocolRecordReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
