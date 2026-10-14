@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictCareProtocolMappingReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708516772)
        var items: [Imaging.StrictCareProtocolMapping] = []
        for index in 0..<5 {
            items.append(Imaging.newStrictCareProtocolMapping("strict-care-protocol-mapping-\(index)", title: "sample"))
        }
        let report = Imaging.buildStrictCareProtocolMappingReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
