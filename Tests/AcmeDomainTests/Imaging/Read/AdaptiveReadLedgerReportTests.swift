@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveReadLedgerReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705153585)
        var items: [Imaging.AdaptiveReadLedger] = []
        for index in 0..<3 {
            items.append(Imaging.newAdaptiveReadLedger("adaptive-read-ledger-\(index)", label: "sample"))
        }
        let report = Imaging.buildAdaptiveReadLedgerReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
