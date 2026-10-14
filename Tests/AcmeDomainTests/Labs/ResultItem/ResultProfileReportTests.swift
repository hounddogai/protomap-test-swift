@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultProfileReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706670940)
        var items: [Labs.ResultProfile] = []
        for index in 0..<5 {
            items.append(Labs.newResultProfile("result-profile-\(index)", label: "sample"))
        }
        let report = Labs.buildResultProfileReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
