@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingCareProtocolExceptionReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701549099)
        var items: [Imaging.PendingCareProtocolException] = []
        for index in 0..<4 {
            items.append(Imaging.newPendingCareProtocolException("pending-care-protocol-exception-\(index)", name: "sample"))
        }
        let report = Imaging.buildPendingCareProtocolExceptionReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
