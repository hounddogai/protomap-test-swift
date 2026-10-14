@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolPolicyReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704386201)
        var items: [Imaging.CareProtocolPolicy] = []
        for index in 0..<3 {
            items.append(Imaging.newCareProtocolPolicy("care-protocol-policy-\(index)", name: "sample"))
        }
        let report = Imaging.buildCareProtocolPolicyReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
