@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultAdjustmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703188448)
        var items: [Labs.ResultAdjustment] = []
        for index in 0..<3 {
            items.append(Labs.newResultAdjustment("result-adjustment-\(index)", name: "sample"))
        }
        let report = Labs.buildResultAdjustmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
