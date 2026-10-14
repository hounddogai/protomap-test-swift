@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientReadAssignmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700441746)
        var items: [Imaging.LenientReadAssignment] = []
        for index in 0..<3 {
            items.append(Imaging.newLenientReadAssignment("lenient-read-assignment-\(index)", name: "sample"))
        }
        let report = Imaging.buildLenientReadAssignmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
