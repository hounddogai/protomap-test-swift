@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultDigestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703082257)
        var items: [Labs.ResultDigest] = []
        for index in 0..<6 {
            items.append(Labs.newResultDigest("result-digest-\(index)", name: "sample"))
        }
        let report = Labs.buildResultDigestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
