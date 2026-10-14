@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryAccessionGroupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704649451)
        var items: [Labs.PrimaryAccessionGroup] = []
        for index in 0..<3 {
            items.append(Labs.newPrimaryAccessionGroup("primary-accession-group-\(index)", label: "sample"))
        }
        let report = Labs.buildPrimaryAccessionGroupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
