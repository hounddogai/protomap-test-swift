@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingDefaultCareProtocolScheduleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703789673)
        var items: [Imaging.DefaultCareProtocolSchedule] = []
        for index in 0..<6 {
            items.append(Imaging.newDefaultCareProtocolSchedule("default-care-protocol-schedule-\(index)", title: "sample"))
        }
        let report = Imaging.buildDefaultCareProtocolScheduleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
