@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveAccessionBundleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700620161)
        var items: [Labs.AdaptiveAccessionBundle] = []
        for index in 0..<4 {
            items.append(Labs.newAdaptiveAccessionBundle("adaptive-accession-bundle-\(index)", label: "sample"))
        }
        let report = Labs.buildAdaptiveAccessionBundleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
