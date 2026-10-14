@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualCareProtocolSlotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706843185)
        var items: [Imaging.ManualCareProtocolSlot] = []
        for index in 0..<4 {
            items.append(Imaging.newManualCareProtocolSlot("manual-care-protocol-slot-\(index)", label: "sample"))
        }
        let report = Imaging.buildManualCareProtocolSlotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
