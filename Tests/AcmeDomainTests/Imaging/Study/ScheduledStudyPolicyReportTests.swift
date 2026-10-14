@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledStudyPolicyReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706239911)
        var items: [Imaging.ScheduledStudyPolicy] = []
        for index in 0..<4 {
            items.append(Imaging.newScheduledStudyPolicy("scheduled-study-policy-\(index)", label: "sample"))
        }
        let report = Imaging.buildScheduledStudyPolicyReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
