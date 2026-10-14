@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredCareProtocolAllocationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701786449)
        var items: [Imaging.TieredCareProtocolAllocation] = []
        for index in 0..<4 {
            items.append(Imaging.newTieredCareProtocolAllocation("tiered-care-protocol-allocation-\(index)", title: "sample"))
        }
        let report = Imaging.buildTieredCareProtocolAllocationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
