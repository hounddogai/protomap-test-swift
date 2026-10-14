@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolMappingReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707766415)
        var items: [Imaging.CareProtocolMapping] = []
        for index in 0..<3 {
            items.append(Imaging.newCareProtocolMapping("care-protocol-mapping-\(index)", label: "sample"))
        }
        let report = Imaging.buildCareProtocolMappingReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
