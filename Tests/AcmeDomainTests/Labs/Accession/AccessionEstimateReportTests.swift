@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionEstimateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702852264)
        var items: [Labs.AccessionEstimate] = []
        for index in 0..<6 {
            items.append(Labs.newAccessionEstimate("accession-estimate-\(index)", label: "sample"))
        }
        let report = Labs.buildAccessionEstimateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
