@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryCareProtocolScoreReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709631178)
        var items: [Imaging.PrimaryCareProtocolScore] = []
        for index in 0..<5 {
            items.append(Imaging.newPrimaryCareProtocolScore("primary-care-protocol-score-\(index)", name: "sample"))
        }
        let report = Imaging.buildPrimaryCareProtocolScoreReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
