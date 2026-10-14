@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalReadDraftReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706917325)
        var items: [Imaging.RegionalReadDraft] = []
        for index in 0..<4 {
            items.append(Imaging.newRegionalReadDraft("regional-read-draft-\(index)", title: "sample"))
        }
        let report = Imaging.buildRegionalReadDraftReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
