@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolTargetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702307749)
        var items: [Imaging.CareProtocolTarget] = []
        for index in 0..<3 {
            items.append(Imaging.newCareProtocolTarget("care-protocol-target-\(index)", title: "sample"))
        }
        let report = Imaging.buildCareProtocolTargetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
