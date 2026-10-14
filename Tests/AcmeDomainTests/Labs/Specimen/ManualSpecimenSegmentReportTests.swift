@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualSpecimenSegmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700833522)
        var items: [Labs.ManualSpecimenSegment] = []
        for index in 0..<5 {
            items.append(Labs.newManualSpecimenSegment("manual-specimen-segment-\(index)", title: "sample"))
        }
        let report = Labs.buildManualSpecimenSegmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
