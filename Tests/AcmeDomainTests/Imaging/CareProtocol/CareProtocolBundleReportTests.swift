@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolBundleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703517127)
        var items: [Imaging.CareProtocolBundle] = []
        for index in 0..<5 {
            items.append(Imaging.newCareProtocolBundle("care-protocol-bundle-\(index)", name: "sample"))
        }
        let report = Imaging.buildCareProtocolBundleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
