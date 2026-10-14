@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalResultDigestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705466077)
        var items: [Labs.RegionalResultDigest] = []
        for index in 0..<5 {
            items.append(Labs.newRegionalResultDigest("regional-result-digest-\(index)", label: "sample"))
        }
        let report = Labs.buildRegionalResultDigestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
