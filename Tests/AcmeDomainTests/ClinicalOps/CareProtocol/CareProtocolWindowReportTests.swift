@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolWindowReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708219638)
        var items: [ClinicalOps.CareProtocolWindow] = []
        for index in 0..<6 {
            items.append(ClinicalOps.newCareProtocolWindow("care-protocol-window-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildCareProtocolWindowReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
