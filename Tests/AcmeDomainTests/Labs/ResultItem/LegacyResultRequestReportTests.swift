@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyResultRequestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705245370)
        var items: [Labs.LegacyResultRequest] = []
        for index in 0..<4 {
            items.append(Labs.newLegacyResultRequest("legacy-result-request-\(index)", title: "sample"))
        }
        let report = Labs.buildLegacyResultRequestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
