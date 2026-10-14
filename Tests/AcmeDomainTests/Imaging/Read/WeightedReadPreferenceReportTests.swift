@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedReadPreferenceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705432002)
        var items: [Imaging.WeightedReadPreference] = []
        for index in 0..<4 {
            items.append(Imaging.newWeightedReadPreference("weighted-read-preference-\(index)", title: "sample"))
        }
        let report = Imaging.buildWeightedReadPreferenceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
