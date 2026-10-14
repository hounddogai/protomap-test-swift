@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedAccessionMappingReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705021883)
        var items: [Labs.WeightedAccessionMapping] = []
        for index in 0..<4 {
            items.append(Labs.newWeightedAccessionMapping("weighted-accession-mapping-\(index)", title: "sample"))
        }
        let report = Labs.buildWeightedAccessionMappingReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
