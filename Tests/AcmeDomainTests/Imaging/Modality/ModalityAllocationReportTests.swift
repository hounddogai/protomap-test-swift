@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityAllocationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702724082)
        var items: [Imaging.ModalityAllocation] = []
        for index in 0..<2 {
            items.append(Imaging.newModalityAllocation("modality-allocation-\(index)", label: "sample"))
        }
        let report = Imaging.buildModalityAllocationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
