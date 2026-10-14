@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedCareProtocolProfileReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706782768)
        var items: [Imaging.WeightedCareProtocolProfile] = []
        for index in 0..<3 {
            items.append(Imaging.newWeightedCareProtocolProfile("weighted-care-protocol-profile-\(index)", title: "sample"))
        }
        let report = Imaging.buildWeightedCareProtocolProfileReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
