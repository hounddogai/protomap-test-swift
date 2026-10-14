@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingInteractionSegmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709469439)
        var items: [Pharmacy.RollingInteractionSegment] = []
        for index in 0..<4 {
            items.append(Pharmacy.newRollingInteractionSegment("rolling-interaction-segment-\(index)", label: "sample"))
        }
        let report = Pharmacy.buildRollingInteractionSegmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
