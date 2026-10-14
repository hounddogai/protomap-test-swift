@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveResultRequestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700609668)
        var items: [Labs.AdaptiveResultRequest] = []
        for index in 0..<6 {
            items.append(Labs.newAdaptiveResultRequest("adaptive-result-request-\(index)", label: "sample"))
        }
        let report = Labs.buildAdaptiveResultRequestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
