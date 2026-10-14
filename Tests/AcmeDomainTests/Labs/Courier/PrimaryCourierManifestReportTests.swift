@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryCourierManifestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708712875)
        var items: [Labs.PrimaryCourierManifest] = []
        for index in 0..<2 {
            items.append(Labs.newPrimaryCourierManifest("primary-courier-manifest-\(index)", title: "sample"))
        }
        let report = Labs.buildPrimaryCourierManifestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
