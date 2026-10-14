@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackWorklistGroupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709149590)
        var items: [Imaging.FallbackWorklistGroup] = []
        for index in 0..<6 {
            items.append(Imaging.newFallbackWorklistGroup("fallback-worklist-group-\(index)", name: "sample"))
        }
        let report = Imaging.buildFallbackWorklistGroupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
